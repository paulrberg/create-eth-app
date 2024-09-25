/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/Moonbirds-Core?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "Moonbirds-Core/@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "Moonbirds-Core/@divergencetech/ethier/contracts/crypto/SignerManager.sol";
import "Moonbirds-Core/@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "Moonbirds-Core/@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "Moonbirds-Core/@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "Moonbirds-Core/@divergencetech/ethier/contracts/sales/FixedPriceSeller.sol";
import "Moonbirds-Core/@divergencetech/ethier/contracts/utils/Monotonic.sol";
import "Moonbirds-Core/@openzeppelin/contracts/token/common/ERC2981.sol";
import "Moonbirds-Core/@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "Moonbirds-Core/@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface ITokenURIGenerator {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// @author divergence.xyz
contract Moonbirds is
    ERC721ACommon,
    BaseTokenURI,
    FixedPriceSeller,
    SignerManager,
    ERC2981,
    AccessControlEnumerable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC721Redeemer for ERC721Redeemer.Claims;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    IERC721 public immutable proof;

    /**
    @notice Role of administrative users allowed to expel a Moonbird from the
    nest.
    @dev See expelFromNest().
     */
    bytes32 public constant EXPULSION_ROLE = keccak256("EXPULSION_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        IERC721 _proof,
        address payable beneficiary,
        address payable royaltyReceiver
    )
        ERC721ACommon(name, symbol)
        BaseTokenURI("")
        FixedPriceSeller(
            2.5 ether,
            // Not including a separate pool for PROOF holders, taking the total
            // to 10k. We don't enforce buyer limits here because it's already
            // done by only issuing a single signature per address, and double
            // enforcement would waste gas.
            Seller.SellerConfig({
                totalInventory: 8_000,
                lockTotalInventory: true,
                maxPerAddress: 0,
                maxPerTx: 0,
                freeQuota: 125,
                lockFreeQuota: false,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {
        proof = _proof;
        _setDefaultRoyalty(royaltyReceiver, 500);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
    @dev Mint tokens purchased via the Seller.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        _safeMint(to, n);

        // We're using two separate pools (one from Seller, and one for PROOF
        // minting), so add an extra layer of checks for this invariant. This
        // should never fail as each pool has its own restriction, and is in
        // place purely for tests (hence assert).
        assert(totalSupply() <= 10_000);
    }

    /**
    @dev Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Mint as a non-holder of PROOF tokens.
     */
    function mintPublic(
        address to,
        bytes32 nonce,
        bytes calldata sig
    ) external payable {
        signers.requireValidSignature(
            signaturePayload(to, nonce),
            sig,
            usedMessages
        );
        _purchase(to, 1);
    }

    /**
    @notice Returns whether the address has minted with the particular nonce. If
    true, future calls to mint() with the same parameters will fail.
    @dev In production we will never issue more than a single nonce per address,
    but this allows for testing with a single address.
     */
    function alreadyMinted(address to, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return
            usedMessages[
                SignatureChecker.generateMessage(signaturePayload(to, nonce))
            ];
    }

    /**
    @dev Constructs the buffer that is hashed for validation with a minting
    signature.
     */
    function signaturePayload(address to, bytes32 nonce)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(to, nonce);
    }

    /**
    @notice Two guaranteed mints per PROOF holder.
    @dev This is specifically tracked because unclaimed tokens will be minted to
    the PROOF wallet, so the pool guarantees an upper bound.
     */
    uint256 public proofPoolRemaining = 2000;

    ERC721Redeemer.Claims private redeemedPROOF;

    /**
    @dev Used by both PROOF-holder and PROOF-admin minting from the pool.
     */
    modifier reducePROOFPool(uint256 n) {
        require(n <= proofPoolRemaining, "Moonbirds: PROOF pool exhausted");
        proofPoolRemaining -= n;
        _;
    }

    /**
    @notice Flag indicating whether holders of PROOF passes can mint.
     */
    bool public proofMintingOpen = false;

    /**
    @notice Sets whether holders of PROOF passes can mint.
     */
    function setPROOFMintingOpen(bool open) external onlyOwner {
        proofMintingOpen = open;
    }

    /**
    @notice Mint as a holder of a PROOF token.
    @dev Repeat a PROOF token ID twice to redeem both of its claims; recurring
    values SHOULD be adjacent for improved gas (eg [1,1,2,2] not [1,2,1,2]).
     */
    function mintPROOF(uint256[] calldata proofTokenIds)
        external
        reducePROOFPool(proofTokenIds.length)
    {
        require(proofMintingOpen, "Moonbirds: PROOF minting closed");
        uint256 n = redeemedPROOF.redeem(2, msg.sender, proof, proofTokenIds);
        _handlePurchase(msg.sender, n, true);
    }

    /**
    @notice Returns how many additional Moonbirds can be claimed with the PROOF
    token.
     */
    function proofClaimsRemaining(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        require(tokenId < 1000, "Token doesn't exist");
        return 2 - redeemedPROOF.claimed(tokenId);
    }

    /**
    @notice Mint unclaimed tokens from the PROOF-holder pool.
     */
    function mintUnclaimed(address to, uint256 n)
        external
        onlyOwner
        reducePROOFPool(n)
    {
        _handlePurchase(to, n, true);
    }

    /**
    @dev tokenId to nesting start time (0 = not nesting).
     */
    mapping(uint256 => uint256) private nestingStarted;

    /**
    @dev Cumulative per-token nesting, excluding the current period.
     */
    mapping(uint256 => uint256) private nestingTotal;

    /**
    @notice Returns the length of time, in seconds, that the Moonbird has
    nested.
    @dev Nesting is tied to a specific Moonbird, not to the owner, so it doesn't
    reset upon sale.
    @return nesting Whether the Moonbird is currently nesting. MAY be true with
    zero current nesting if in the same block as nesting began.
    @return current Zero if not currently nesting, otherwise the length of time
    since the most recent nesting began.
    @return total Total period of time for which the Moonbird has nested across
    its life, including the current period.
     */
    function nestingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool nesting,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = nestingStarted[tokenId];
        if (start != 0) {
            nesting = true;
            current = block.timestamp - start;
        }
        total = current + nestingTotal[tokenId];
    }

    /**
    @dev MUST only be modified by safeTransferWhileNesting(); if set to 2 then
    the _beforeTokenTransfer() block while nesting is disabled.
     */
    uint256 private nestingTransfer = 1;

    /**
    @notice Transfer a token between addresses while the Moonbird is minting,
    thus not resetting the nesting period.
     */
    function safeTransferWhileNesting(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "Moonbirds: Only owner");
        nestingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        nestingTransfer = 1;
    }

    /**
    @dev Block transfers while nesting.
     */
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(
                nestingStarted[tokenId] == 0 || nestingTransfer == 2,
                "Moonbirds: nesting"
            );
        }
    }

    /**
    @dev Emitted when a Moonbird begins nesting.
     */
    event Nested(uint256 indexed tokenId);

    /**
    @dev Emitted when a Moonbird stops nesting; either through standard means or
    by expulsion.
     */
    event Unnested(uint256 indexed tokenId);

    /**
    @dev Emitted when a Moonbird is expelled from the nest.
     */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether nesting is currently allowed.
    @dev If false then nesting is blocked, but unnesting is always allowed.
     */
    bool public nestingOpen = false;

    /**
    @notice Toggles the `nestingOpen` flag.
     */
    function setNestingOpen(bool open) external onlyOwner {
        nestingOpen = open;
    }

    /**
    @notice Changes the Moonbird's nesting status.
    */
    function toggleNesting(uint256 tokenId)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        uint256 start = nestingStarted[tokenId];
        if (start == 0) {
            require(nestingOpen, "Moonbirds: nesting closed");
            nestingStarted[tokenId] = block.timestamp;
            emit Nested(tokenId);
        } else {
            nestingTotal[tokenId] += block.timestamp - start;
            nestingStarted[tokenId] = 0;
            emit Unnested(tokenId);
        }
    }

    /**
    @notice Changes the Moonbirds' nesting statuss (what's the plural of status?
    statii? statuses? status? The plural of sheep is sheep; maybe it's also the
    plural of status).
    @dev Changes the Moonbirds' nesting sheep (see @notice).
     */
    function toggleNesting(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleNesting(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel a Moonbird from the nest.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has nested and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting bird to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because nesting would then be all-or-nothing for all of a particular owner's
    Moonbirds.
     */
    function expelFromNest(uint256 tokenId) external onlyRole(EXPULSION_ROLE) {
        require(nestingStarted[tokenId] != 0, "Moonbirds: not nested");
        nestingTotal[tokenId] += block.timestamp - nestingStarted[tokenId];
        nestingStarted[tokenId] = 0;
        emit Unnested(tokenId);
        emit Expelled(tokenId);
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    /**
    @notice If set, contract to which tokenURI() calls are proxied.
     */
    ITokenURIGenerator public renderingContract;

    /**
    @notice Sets the optional tokenURI override contract.
     */
    function setRenderingContract(ITokenURIGenerator _contract)
        external
        onlyOwner
    {
        renderingContract = _contract;
    }

    /**
    @notice If renderingContract is set then returns its tokenURI(tokenId)
    return value, otherwise returns the standard baseTokenURI + tokenId.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (address(renderingContract) != address(0)) {
            return renderingContract.tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
