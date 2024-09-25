/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Eigenlayer?utm=code
  */
  
  // SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "../interfaces/IBLSPublicKeyCompendium.sol";
import "../libraries/BN254.sol";

/**
 * @title A shared contract for EigenLayer operators to register their BLS public keys.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 */
contract BLSPublicKeyCompendium is IBLSPublicKeyCompendium {
    //Hash of the zero public key: BN254.hashG1Point(G1Point(0,0))
    bytes32 internal constant ZERO_PK_HASH = hex"ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5";

    /// @notice mapping from operator address to pubkey hash
    mapping(address => bytes32) public operatorToPubkeyHash;
    /// @notice mapping from pubkey hash to operator address
    mapping(bytes32 => address) public pubkeyHashToOperator;

    // EVENTS
    /// @notice Emitted when `operator` registers with the public key `pk`.
    event NewPubkeyRegistration(address operator, BN254.G1Point pubkeyG1, BN254.G2Point pubkeyG2);

    /**
     * @notice Called by an operator to register themselves as the owner of a BLS public key and reveal their G1 and G2 public key.
     * @param s is the field element of the operator's Schnorr signature
     * @param rPoint is the group element of the operator's Schnorr signature
     * @param pubkeyG1 is the the G1 pubkey of the operator
     * @param pubkeyG2 is the G2 with the same private key as the pubkeyG1
     */
    function registerBLSPublicKey(uint256 s, BN254.G1Point memory rPoint, BN254.G1Point memory pubkeyG1, BN254.G2Point memory pubkeyG2) external {
        // calculate -g1
        BN254.G1Point memory negGeneratorG1 = BN254.negate(BN254.G1Point({X: 1, Y: 2}));
        // verify a Schnorr signature (s, R) of pubkeyG1
        // calculate s*-g1 + (R + H(msg.sender, P, R)*P) = 0
        // which is the Schnorr signature verification equation
        BN254.G1Point memory shouldBeZero = 
            BN254.plus(
                BN254.scalar_mul(negGeneratorG1, s),
                BN254.plus(
                    rPoint,
                    BN254.scalar_mul(
                        pubkeyG1,
                        uint256(keccak256(abi.encodePacked(msg.sender, pubkeyG1.X, pubkeyG1.Y, rPoint.X, rPoint.Y))) % BN254.FR_MODULUS
                    )
                )
            );

        require(shouldBeZero.X == 0 && shouldBeZero.Y == 0, "BLSPublicKeyCompendium.registerBLSPublicKey: incorrect schnorr singature");

        // verify that the G2 pubkey has the same discrete log as the G1 pubkey
        // e(P, [1]_2) = e([-1]_1, P')
        require(BN254.pairing(
            pubkeyG1,
            BN254.generatorG2(),
            negGeneratorG1,
            pubkeyG2
        ), "BLSPublicKeyCompendium.registerBLSPublicKey: G1 and G2 private key do not match");

        // getting pubkey hash
        bytes32 pubkeyHash = BN254.hashG1Point(pubkeyG1);

        require(pubkeyHash != ZERO_PK_HASH, "BLSPublicKeyCompendium.registerBLSPublicKey: operator attempting to register the zero public key");

        require(
            operatorToPubkeyHash[msg.sender] == bytes32(0),
            "BLSPublicKeyCompendium.registerBLSPublicKey: operator already registered pubkey"
        );
        require(
            pubkeyHashToOperator[pubkeyHash] == address(0),
            "BLSPublicKeyCompendium.registerBLSPublicKey: public key already registered"
        );

        // store updates
        operatorToPubkeyHash[msg.sender] = pubkeyHash;
        pubkeyHashToOperator[pubkeyHash] = msg.sender;

        emit NewPubkeyRegistration(msg.sender, pubkeyG1, pubkeyG2);
    }
}
