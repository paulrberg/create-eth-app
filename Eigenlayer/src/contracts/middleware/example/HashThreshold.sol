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

import "Eigenlayer/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "Eigenlayer/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import "../../interfaces/IServiceManager.sol";
import "./ECDSARegistry.sol";

/**
 * @title An EigenLayer middleware example service manager that slashes validators that sign a message that, when hashed 10 times starts with less than a certain number of 0s.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 */
contract HashThreshold is Ownable, IServiceManager {
    uint32 constant disputePeriodBlocks = 1 days / 12 seconds;
    uint8 constant numZeroes = 5;
    ISlasher public immutable slasher;
    ECDSARegistry public immutable registry;


    struct CertifiedMessageMetadata {
        bytes32 signaturesHash;
        uint32 validAfterBlock;
    }

    uint32 public taskNumber = 0;
    uint32 public latestServeUntilBlock = 0;
    mapping(bytes32 => CertifiedMessageMetadata) public certifiedMessageMetadatas;

    event MessageCertified(bytes32);

    modifier onlyRegistry {
        require(msg.sender == address(registry), "Only registry can call this function");
        _;
    }

    constructor(
        ISlasher _slasher,
        ECDSARegistry _registry
    ) {
        slasher = _slasher;
        registry = _registry;
    }

    function owner() public view override(Ownable, IServiceManager) returns (address) {
        return Ownable.owner();
    }

    function decaHash(bytes32 message) public pure returns (bytes32) {
        bytes32 hash = message;
        for (uint256 i = 0; i < 10; i++) {
            hash = keccak256(abi.encodePacked(hash));
        }
        return hash;
    }

    /**
     * This function is called by anyone to certify a message. Signers are certifying that the decahashed message starts with at least `numZeros` 0s.
     * 
     * @param message The message to certify
     * @param signatures The signatures of the message, certifying it
     */
    function submitSignatures(bytes32 message, bytes calldata signatures) external {
        // we check that the message has not already been certified
        require(certifiedMessageMetadatas[message].validAfterBlock == 0, "Message already certified");
        // this makes it so that the signatures are viewable in calldata
        require(msg.sender == tx.origin, "EOA must call this function");
        uint128 stakeSigned = 0;
        for(uint256 i = 0; i < signatures.length; i += 65) {
            // we fetch all the signers and check their signatures and their stake
            address signer = ECDSA.recover(message, signatures[i:i+65]);
            require(registry.isActiveOperator(signer), "Signer is not an active operator");
            stakeSigned += registry.firstQuorumStakedByOperator(signer);
        }
        // We require that 2/3 of the stake signed the message
        // We only take the first quorum stake because this is a single quorum middleware
        (uint96 totalStake,) = registry.totalStake();
        require(stakeSigned >= 666667 * uint256(totalStake) / 1000000, "Need more than 2/3 of stake to sign");

        uint32 newLatestServeUntilBlock = uint32(block.number + disputePeriodBlocks);

        certifiedMessageMetadatas[message] = CertifiedMessageMetadata({
            validAfterBlock: newLatestServeUntilBlock,
            signaturesHash: keccak256(signatures)
        });

        // increment global service manager values
        taskNumber++;
        // Note: latestServeUntilBlock is the latest block at which anyone currently staked on the middleware can be frozen
        latestServeUntilBlock = newLatestServeUntilBlock;

        emit MessageCertified(message);
    }


    /**
     * This function is called by anyone to slash the signers of an invalid message that has been certified.
     * 
     * @param message The message to slash the signers of
     * @param signatures The signatures that certified the message
     */
    function slashSigners(bytes32 message, bytes calldata signatures) external {
        CertifiedMessageMetadata memory certifiedMessageMetadata = certifiedMessageMetadatas[message];
        // we check that the message has been certified
        require(certifiedMessageMetadata.validAfterBlock > block.number, "Dispute period has passed");
        // we check that the signatures match the ones that were certified
        require(certifiedMessageMetadata.signaturesHash == keccak256(signatures), "Signatures do not match");
        // we check that the message hashes to enough zeroes
        require(decaHash(message) >> (256 - numZeroes) == 0, "Message does not hash to enough zeroes");
        // we freeze all the signers
        for (uint i = 0; i < signatures.length; i += 65) {
            // this is eigenlayer's means of escalating an operators stake for review for slashing
            // this immediately prevents all withdrawals for the operator and stakers delegated to them
            slasher.freezeOperator(ECDSA.recover(message, signatures[i:i+65]));
        }
        // we invalidate the message
        certifiedMessageMetadatas[message].validAfterBlock = type(uint32).max;
    }

    /// @inheritdoc IServiceManager
    function freezeOperator(address operator) external onlyRegistry {
        slasher.freezeOperator(operator);
    }

    /// @inheritdoc IServiceManager
    function recordFirstStakeUpdate(address operator, uint32 serveUntilBlock) external onlyRegistry {
        slasher.recordFirstStakeUpdate(operator, serveUntilBlock);
    }

    /// @inheritdoc IServiceManager
    function recordLastStakeUpdateAndRevokeSlashingAbility(address operator, uint32 serveUntilBlock) external onlyRegistry {
        slasher.recordLastStakeUpdateAndRevokeSlashingAbility(operator, serveUntilBlock);
    }

    /// @inheritdoc IServiceManager
    function recordStakeUpdate(address operator, uint32 updateBlock, uint32 serveUntilBlock, uint256 prevElement) external onlyRegistry {
        slasher.recordStakeUpdate(operator, updateBlock, serveUntilBlock, prevElement);
    }
}
