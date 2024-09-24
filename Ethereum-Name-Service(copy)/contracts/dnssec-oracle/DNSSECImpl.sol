/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Ethereum-Name-Service?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./Owned.sol";
import "./BytesUtils.sol";
import "./RRUtils.sol";
import "./DNSSEC.sol";
import "./algorithms/Algorithm.sol";
import "./digests/Digest.sol";
import "Ethereum-Name-Service/@ensdomains/buffer/contracts/Buffer.sol";

/*
 * @dev An oracle contract that verifies and stores DNSSEC-validated DNS records.
 * @note This differs from the DNSSEC spec defined in RFC4034 and RFC4035 in some key regards:
 *       - NSEC & NSEC3 are not supported; only positive proofs are allowed.
 *       - Proofs involving wildcard names will not validate.
 *       - TTLs on records are ignored, as data is not stored persistently.
 *       - Canonical form of names is not checked; in ENS this is done on the frontend, so submitting
 *         proofs with non-canonical names will only result in registering unresolvable ENS names.
 */
contract DNSSECImpl is DNSSEC, Owned {
    using Buffer for Buffer.buffer;
    using BytesUtils for bytes;
    using RRUtils for *;

    uint16 constant DNSCLASS_IN = 1;

    uint16 constant DNSTYPE_DS = 43;
    uint16 constant DNSTYPE_DNSKEY = 48;

    uint256 constant DNSKEY_FLAG_ZONEKEY = 0x100;

    error InvalidLabelCount(bytes name, uint256 labelsExpected);
    error SignatureNotValidYet(uint32 inception, uint32 now);
    error SignatureExpired(uint32 expiration, uint32 now);
    error InvalidClass(uint16 class);
    error InvalidRRSet();
    error SignatureTypeMismatch(uint16 rrsetType, uint16 sigType);
    error InvalidSignerName(bytes rrsetName, bytes signerName);
    error InvalidProofType(uint16 proofType);
    error ProofNameMismatch(bytes signerName, bytes proofName);
    error NoMatchingProof(bytes signerName);

    mapping(uint8 => Algorithm) public algorithms;
    mapping(uint8 => Digest) public digests;

    /**
     * @dev Constructor.
     * @param _anchors The binary format RR entries for the root DS records.
     */
    constructor(bytes memory _anchors) {
        // Insert the 'trust anchors' - the key hashes that start the chain
        // of trust for all other records.
        anchors = _anchors;
    }

    /**
     * @dev Sets the contract address for a signature verification algorithm.
     *      Callable only by the owner.
     * @param id The algorithm ID
     * @param algo The address of the algorithm contract.
     */
    function setAlgorithm(uint8 id, Algorithm algo) public owner_only {
        algorithms[id] = algo;
        emit AlgorithmUpdated(id, address(algo));
    }

    /**
     * @dev Sets the contract address for a digest verification algorithm.
     *      Callable only by the owner.
     * @param id The digest ID
     * @param digest The address of the digest contract.
     */
    function setDigest(uint8 id, Digest digest) public owner_only {
        digests[id] = digest;
        emit DigestUpdated(id, address(digest));
    }

    /**
     * @dev Takes a chain of signed DNS records, verifies them, and returns the data from the last record set in the chain.
     *      Reverts if the records do not form an unbroken chain of trust to the DNSSEC anchor records.
     * @param input A list of signed RRSets.
     * @return rrs The RRData from the last RRSet in the chain.
     * @return inception The inception time of the signed record set.
     */
    function verifyRRSet(
        RRSetWithSignature[] memory input
    )
        external
        view
        virtual
        override
        returns (bytes memory rrs, uint32 inception)
    {
        return verifyRRSet(input, block.timestamp);
    }

    /**
     * @dev Takes a chain of signed DNS records, verifies them, and returns the data from the last record set in the chain.
     *      Reverts if the records do not form an unbroken chain of trust to the DNSSEC anchor records.
     * @param input A list of signed RRSets.
     * @param now The Unix timestamp to validate the records at.
     * @return rrs The RRData from the last RRSet in the chain.
     * @return inception The inception time of the signed record set.
     */
    function verifyRRSet(
        RRSetWithSignature[] memory input,
        uint256 now
    )
        public
        view
        virtual
        override
        returns (bytes memory rrs, uint32 inception)
    {
        bytes memory proof = anchors;
        for (uint256 i = 0; i < input.length; i++) {
            RRUtils.SignedSet memory rrset = validateSignedSet(
                input[i],
                proof,
                now
            );
            proof = rrset.data;
            inception = rrset.inception;
        }
        return (proof, inception);
    }

    /**
     * @dev Validates an RRSet against the already trusted RR provided in `proof`.
     *
     * @param input The signed RR set. This is in the format described in section
     *        5.3.2 of RFC4035: The RRDATA section from the RRSIG without the signature
     *        data, followed by a series of canonicalised RR records that the signature
     *        applies to.
     * @param proof The DNSKEY or DS to validate the signature against.
     * @param now The current timestamp.
     */
    function validateSignedSet(
        RRSetWithSignature memory input,
        bytes memory proof,
        uint256 now
    ) internal view returns (RRUtils.SignedSet memory rrset) {
        rrset = input.rrset.readSignedSet();

        // Do some basic checks on the RRs and extract the name
        bytes memory name = validateRRs(rrset, rrset.typeCovered);
        if (name.labelCount(0) != rrset.labels) {
            revert InvalidLabelCount(name, rrset.labels);
        }
        rrset.name = name;

        // All comparisons involving the Signature Expiration and
        // Inception fields MUST use "serial number arithmetic", as
        // defined in RFC 1982

        // o  The validator's notion of the current time MUST be less than or
        //    equal to the time listed in the RRSIG RR's Expiration field.
        if (!RRUtils.serialNumberGte(rrset.expiration, uint32(now))) {
            revert SignatureExpired(rrset.expiration, uint32(now));
        }

        // o  The validator's notion of the current time MUST be greater than or
        //    equal to the time listed in the RRSIG RR's Inception field.
        if (!RRUtils.serialNumberGte(uint32(now), rrset.inception)) {
            revert SignatureNotValidYet(rrset.inception, uint32(now));
        }

        // Validate the signature
        verifySignature(name, rrset, input, proof);

        return rrset;
    }

    /**
     * @dev Validates a set of RRs.
     * @param rrset The RR set.
     * @param typecovered The type covered by the RRSIG record.
     */
    function validateRRs(
        RRUtils.SignedSet memory rrset,
        uint16 typecovered
    ) internal pure returns (bytes memory name) {
        // Iterate over all the RRs
        for (
            RRUtils.RRIterator memory iter = rrset.rrs();
            !iter.done();
            iter.next()
        ) {
            // We only support class IN (Internet)
            if (iter.class != DNSCLASS_IN) {
                revert InvalidClass(iter.class);
            }

            if (name.length == 0) {
                name = iter.name();
            } else {
                // Name must be the same on all RRs. We do things this way to avoid copying the name
                // repeatedly.
                if (
                    name.length != iter.data.nameLength(iter.offset) ||
                    !name.equals(0, iter.data, iter.offset, name.length)
                ) {
                    revert InvalidRRSet();
                }
            }

            // o  The RRSIG RR's Type Covered field MUST equal the RRset's type.
            if (iter.dnstype != typecovered) {
                revert SignatureTypeMismatch(iter.dnstype, typecovered);
            }
        }
    }

    /**
     * @dev Performs signature verification.
     *
     * Throws or reverts if unable to verify the record.
     *
     * @param name The name of the RRSIG record, in DNS label-sequence format.
     * @param data The original data to verify.
     * @param proof A DS or DNSKEY record that's already verified by the oracle.
     */
    function verifySignature(
        bytes memory name,
        RRUtils.SignedSet memory rrset,
        RRSetWithSignature memory data,
        bytes memory proof
    ) internal view {
        // o  The RRSIG RR's Signer's Name field MUST be the name of the zone
        //    that contains the RRset.
        if (!name.isSubdomainOf(rrset.signerName)) {
            revert InvalidSignerName(name, rrset.signerName);
        }

        RRUtils.RRIterator memory proofRR = proof.iterateRRs(0);
        // Check the proof
        if (proofRR.dnstype == DNSTYPE_DS) {
            verifyWithDS(rrset, data, proofRR);
        } else if (proofRR.dnstype == DNSTYPE_DNSKEY) {
            verifyWithKnownKey(rrset, data, proofRR);
        } else {
            revert InvalidProofType(proofRR.dnstype);
        }
    }

    /**
     * @dev Attempts to verify a signed RRSET against an already known public key.
     * @param rrset The signed set to verify.
     * @param data The original data the signed set was read from.
     * @param proof The serialized DS or DNSKEY record to use as proof.
     */
    function verifyWithKnownKey(
        RRUtils.SignedSet memory rrset,
        RRSetWithSignature memory data,
        RRUtils.RRIterator memory proof
    ) internal view {
        // Check the DNSKEY's owner name matches the signer name on the RRSIG
        for (; !proof.done(); proof.next()) {
            bytes memory proofName = proof.name();
            if (!proofName.equals(rrset.signerName)) {
                revert ProofNameMismatch(rrset.signerName, proofName);
            }

            bytes memory keyrdata = proof.rdata();
            RRUtils.DNSKEY memory dnskey = keyrdata.readDNSKEY(
                0,
                keyrdata.length
            );
            if (verifySignatureWithKey(dnskey, keyrdata, rrset, data)) {
                return;
            }
        }
        revert NoMatchingProof(rrset.signerName);
    }

    /**
     * @dev Attempts to verify some data using a provided key and a signature.
     * @param dnskey The dns key record to verify the signature with.
     * @param rrset The signed RRSET being verified.
     * @param data The original data `rrset` was decoded from.
     * @return True iff the key verifies the signature.
     */
    function verifySignatureWithKey(
        RRUtils.DNSKEY memory dnskey,
        bytes memory keyrdata,
        RRUtils.SignedSet memory rrset,
        RRSetWithSignature memory data
    ) internal view returns (bool) {
        // TODO: Check key isn't expired, unless updating key itself

        // The Protocol Field MUST have value 3 (RFC4034 2.1.2)
        if (dnskey.protocol != 3) {
            return false;
        }

        // o The RRSIG RR's Signer's Name, Algorithm, and Key Tag fields MUST
        //   match the owner name, algorithm, and key tag for some DNSKEY RR in
        //   the zone's apex DNSKEY RRset.
        if (dnskey.algorithm != rrset.algorithm) {
            return false;
        }
        uint16 computedkeytag = keyrdata.computeKeytag();
        if (computedkeytag != rrset.keytag) {
            return false;
        }

        // o The matching DNSKEY RR MUST be present in the zone's apex DNSKEY
        //   RRset, and MUST have the Zone Flag bit (DNSKEY RDATA Flag bit 7)
        //   set.
        if (dnskey.flags & DNSKEY_FLAG_ZONEKEY == 0) {
            return false;
        }

        Algorithm algorithm = algorithms[dnskey.algorithm];
        if (address(algorithm) == address(0)) {
            return false;
        }
        return algorithm.verify(keyrdata, data.rrset, data.sig);
    }

    /**
     * @dev Attempts to verify a signed RRSET against an already known hash. This function assumes
     *      that the record
     * @param rrset The signed set to verify.
     * @param data The original data the signed set was read from.
     * @param proof The serialized DS or DNSKEY record to use as proof.
     */
    function verifyWithDS(
        RRUtils.SignedSet memory rrset,
        RRSetWithSignature memory data,
        RRUtils.RRIterator memory proof
    ) internal view {
        uint256 proofOffset = proof.offset;
        for (
            RRUtils.RRIterator memory iter = rrset.rrs();
            !iter.done();
            iter.next()
        ) {
            if (iter.dnstype != DNSTYPE_DNSKEY) {
                revert InvalidProofType(iter.dnstype);
            }

            bytes memory keyrdata = iter.rdata();
            RRUtils.DNSKEY memory dnskey = keyrdata.readDNSKEY(
                0,
                keyrdata.length
            );
            if (verifySignatureWithKey(dnskey, keyrdata, rrset, data)) {
                // It's self-signed - look for a DS record to verify it.
                if (
                    verifyKeyWithDS(rrset.signerName, proof, dnskey, keyrdata)
                ) {
                    return;
                }
                // Rewind proof iterator to the start for the next loop iteration.
                proof.nextOffset = proofOffset;
                proof.next();
            }
        }
        revert NoMatchingProof(rrset.signerName);
    }

    /**
     * @dev Attempts to verify a key using DS records.
     * @param keyname The DNS name of the key, in DNS label-sequence format.
     * @param dsrrs The DS records to use in verification.
     * @param dnskey The dnskey to verify.
     * @param keyrdata The RDATA section of the key.
     * @return True if a DS record verifies this key.
     */
    function verifyKeyWithDS(
        bytes memory keyname,
        RRUtils.RRIterator memory dsrrs,
        RRUtils.DNSKEY memory dnskey,
        bytes memory keyrdata
    ) internal view returns (bool) {
        uint16 keytag = keyrdata.computeKeytag();
        for (; !dsrrs.done(); dsrrs.next()) {
            bytes memory proofName = dsrrs.name();
            if (!proofName.equals(keyname)) {
                revert ProofNameMismatch(keyname, proofName);
            }

            RRUtils.DS memory ds = dsrrs.data.readDS(
                dsrrs.rdataOffset,
                dsrrs.nextOffset - dsrrs.rdataOffset
            );
            if (ds.keytag != keytag) {
                continue;
            }
            if (ds.algorithm != dnskey.algorithm) {
                continue;
            }

            Buffer.buffer memory buf;
            buf.init(keyname.length + keyrdata.length);
            buf.append(keyname);
            buf.append(keyrdata);
            if (verifyDSHash(ds.digestType, buf.buf, ds.digest)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Attempts to verify a DS record's hash value against some data.
     * @param digesttype The digest ID from the DS record.
     * @param data The data to digest.
     * @param digest The digest data to check against.
     * @return True iff the digest matches.
     */
    function verifyDSHash(
        uint8 digesttype,
        bytes memory data,
        bytes memory digest
    ) internal view returns (bool) {
        if (address(digests[digesttype]) == address(0)) {
            return false;
        }
        return digests[digesttype].verify(data, digest);
    }
}
