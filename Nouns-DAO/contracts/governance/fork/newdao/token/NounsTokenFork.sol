/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Nouns-DAO?utm=code
  */
  
  // SPDX-License-Identifier: GPL-3.0

/// @title The Nouns ERC-721 token, adjusted for forks

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.19;

import { OwnableUpgradeable } from 'Nouns-DAO/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { ERC721CheckpointableUpgradeable } from './base/ERC721CheckpointableUpgradeable.sol';
import { INounsDescriptorMinimal } from '../../../../interfaces/INounsDescriptorMinimal.sol';
import { INounsSeeder } from '../../../../interfaces/INounsSeeder.sol';
import { INounsTokenFork } from './INounsTokenFork.sol';
import { IERC721 } from 'Nouns-DAO/@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { UUPSUpgradeable } from 'Nouns-DAO/@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import { INounsDAOForkEscrow } from '../../../NounsDAOInterfaces.sol';

/**
 * @dev This contract is a fork of NounsToken, with the following changes:
 * - Added upgradeablity via UUPSUpgradeable.
 * - Inheriting from an unmodified ERC721, so that the double Transfer event emission that
 *   NounsToken performs is gone, in favor of the standard single event.
 * - Added functions to claim tokens from a Nouns Fork escrow, or during the forking period.
 * - Removed the proxyRegistry feature that whitelisted OpenSea.
 * - Removed `noundersDAO` and the founder reward every 10 mints.
 * For additional context see `ERC721CheckpointableUpgradeable`.
 */
contract NounsTokenFork is INounsTokenFork, OwnableUpgradeable, ERC721CheckpointableUpgradeable, UUPSUpgradeable {
    error OnlyOwner();
    error OnlyTokenOwnerCanClaim();
    error OnlyOriginalDAO();
    error NoundersCannotBeAddressZero();
    error OnlyDuringForkingPeriod();

    string public constant NAME = 'NounsTokenFork';

    /// @notice  An address who has permissions to mint Nouns
    address public minter;

    /// @notice The Nouns token URI descriptor
    INounsDescriptorMinimal public descriptor;

    /// @notice The Nouns token seeder
    INounsSeeder public seeder;

    /// @notice The escrow contract used to verify ownership of the original Nouns in the post-fork claiming process
    INounsDAOForkEscrow public escrow;

    /// @notice The fork ID, used when querying the escrow for token ownership
    uint32 public forkId;

    /// @notice How many tokens are still available to be claimed by Nouners who put their original Nouns in escrow
    uint256 public remainingTokensToClaim;

    /// @notice The forking period expiration timestamp, after which new tokens cannot be claimed by the original DAO
    uint256 public forkingPeriodEndTimestamp;

    /// @notice Whether the minter can be updated
    bool public isMinterLocked;

    /// @notice Whether the descriptor can be updated
    bool public isDescriptorLocked;

    /// @notice Whether the seeder can be updated
    bool public isSeederLocked;

    /// @notice The noun seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    /// @notice The internal noun ID tracker
    uint256 private _currentNounId;

    /// @notice IPFS content hash of contract-level metadata
    string private _contractURIHash = 'QmZi1n79FqWt2tTLwCqiy6nLM6xLGRsEPQ5JmReJQKNNzX';

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'Seeder is locked');
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    constructor() initializer {}

    function initialize(
        address _owner,
        address _minter,
        INounsDAOForkEscrow _escrow,
        uint32 _forkId,
        uint256 startNounId,
        uint256 tokensToClaim,
        uint256 _forkingPeriodEndTimestamp
    ) external initializer {
        __ERC721_init('Nouns', 'NOUN');
        _transferOwnership(_owner);
        minter = _minter;
        escrow = _escrow;
        forkId = _forkId;
        _currentNounId = startNounId;
        remainingTokensToClaim = tokensToClaim;
        forkingPeriodEndTimestamp = _forkingPeriodEndTimestamp;

        NounsTokenFork originalToken = NounsTokenFork(address(escrow.nounsToken()));
        descriptor = originalToken.descriptor();
        seeder = originalToken.seeder();
    }

    /**
     * @notice Claim new tokens if you escrowed original Nouns and forked into a new DAO governed by holders of this
     * token.
     * @dev Reverts if the sender is not the owner of the escrowed token.
     * @param tokenIds The token IDs to claim
     */
    function claimFromEscrow(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 nounId = tokenIds[i];
            if (escrow.ownerOfEscrowedToken(forkId, nounId) != msg.sender) revert OnlyTokenOwnerCanClaim();

            _mintWithOriginalSeed(msg.sender, nounId);
        }

        remainingTokensToClaim -= tokenIds.length;
    }

    /**
     * @notice The original DAO can claim tokens during the forking period, on behalf of Nouners who choose to join
     * a new fork DAO. Does not allow the original DAO to claim once the forking period has ended.
     * @dev Assumes the original DAO is honest during the forking period.
     * @param to The recipient of the tokens
     * @param tokenIds The token IDs to claim
     */
    function claimDuringForkPeriod(address to, uint256[] calldata tokenIds) external {
        uint256 currentNounId = _currentNounId;
        uint256 maxNounId = 0;
        if (msg.sender != escrow.dao()) revert OnlyOriginalDAO();
        if (block.timestamp >= forkingPeriodEndTimestamp) revert OnlyDuringForkingPeriod();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 nounId = tokenIds[i];
            _mintWithOriginalSeed(to, nounId);

            if (tokenIds[i] > maxNounId) maxNounId = tokenIds[i];
        }

        // This treats an important case:
        // During a forking period, people can buy new Nouns on auction, with a higher ID than the auction ID at forking
        // They can then join the fork with those IDs
        // If we don't increment currentNounId, unpausing the fork auction house would revert
        // Since it would attempt to mint a noun with an ID that already exists
        if (maxNounId >= currentNounId) _currentNounId = maxNounId + 1;
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Mint a Noun to the minter
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        return _mintTo(minter, _currentNounId++);
    }

    /**
     * @notice Burn a noun.
     */
    function burn(uint256 nounId) public override onlyMinter {
        _burn(nounId);
        emit NounBurned(nounId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'NounsToken: URI query for nonexistent token');
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'NounsToken: URI query for nonexistent token');
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(INounsDescriptorMinimal _descriptor) external override onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(INounsSeeder _seeder) external override onlyOwner whenSeederNotLocked {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

    /**
     * @notice Mint a Noun with `nounId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 nounId) internal returns (uint256) {
        INounsSeeder.Seed memory seed = seeds[nounId] = seeder.generateSeed(nounId, descriptor);

        _mint(to, nounId);
        emit NounCreated(nounId, seed);

        return nounId;
    }

    /**
     * @notice Mint a new token using the original Nouns seed.
     */
    function _mintWithOriginalSeed(address to, uint256 nounId) internal {
        (uint48 background, uint48 body, uint48 accessory, uint48 head, uint48 glasses) = NounsTokenFork(
            address(escrow.nounsToken())
        ).seeds(nounId);
        INounsSeeder.Seed memory seed = INounsSeeder.Seed(background, body, accessory, head, glasses);

        seeds[nounId] = seed;
        _mint(to, nounId);

        emit NounCreated(nounId, seed);
    }

    /**
     * @dev Reverts when `msg.sender` is not the owner of this contract; in the case of Noun DAOs it should be the
     * DAO's treasury contract.
     */
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}
