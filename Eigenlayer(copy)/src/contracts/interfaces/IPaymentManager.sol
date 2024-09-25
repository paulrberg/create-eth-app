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
pragma solidity >=0.5.0;

import "Eigenlayer/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface for a `PaymentManager` contract.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 */
interface IPaymentManager {
    enum DissectionType {
        INVALID,
        FIRST_HALF,
        SECOND_HALF
    }
    enum PaymentStatus {
        REDEEMED,
        COMMITTED,
        CHALLENGED
    }
    enum ChallengeStatus {
        RESOLVED,
        OPERATOR_TURN,
        CHALLENGER_TURN,
        OPERATOR_TURN_ONE_STEP,
        CHALLENGER_TURN_ONE_STEP
    }

    /**
     * @notice used for storing information on the most recent payment made to the operator
     */
    struct Payment {
        // taskNumber starting from which payment is being claimed
        uint32 fromTaskNumber;
        // taskNumber until which payment is being claimed (exclusive)
        uint32 toTaskNumber;
        // recording when the payment will optimistically be confirmed; used for fraudproof period
        uint32 confirmAt;
        // payment for range [fromTaskNumber, toTaskNumber)
        /// @dev max 1.3e36, keep in mind for token decimals
        uint96 amount;
        /**
         * @notice The possible statuses are:
         * - 0: REDEEMED,
         * - 1: COMMITTED,
         * - 2: CHALLENGED
         */
        PaymentStatus status;
        uint256 challengeAmount; //account for if challengeAmount changed
    }

    /**
     * @notice used for storing information on the payment challenge as part of the interactive process
     */
    struct PaymentChallenge {
        // operator whose payment claim is being challenged,
        address operator;
        // the entity challenging with the fraudproof
        address challenger;
        // address of the service manager contract
        address serviceManager;
        // the TaskNumber from which payment has been computed
        uint32 fromTaskNumber;
        // the TaskNumber until which payment has been computed to
        uint32 toTaskNumber;
        // reward amount the challenger claims is for the first half of tasks
        uint96 amount1;
        // reward amount the challenger claims is for the second half of tasks
        uint96 amount2;
        // used for recording the time when challenge was created
        uint32 settleAt; // when committed, used for fraudproof period
        // indicates the status of the challenge
        /**
         * @notice The possible statuses are:
         * - 0: RESOLVED,
         * - 1: operator turn (dissection),
         * - 2: challenger turn (dissection),
         * - 3: operator turn (one step),
         * - 4: challenger turn (one step)
         */
        ChallengeStatus status;
    }

    struct TotalStakes {
        uint256 signedStakeFirstQuorum;
        uint256 signedStakeSecondQuorum;
    }

    /**
     * @notice deposit one-time fees by the `msg.sender` with this contract to pay for future tasks of this middleware
     * @param depositFor could be the `msg.sender` themselves, or a different address for whom `msg.sender` is depositing these future fees
     * @param amount is amount of futures fees being deposited
     */
    function depositFutureFees(address depositFor, uint256 amount) external;

    /// @notice Allows the `allowed` address to spend up to `amount` of the `msg.sender`'s funds that have been deposited in this contract
    function setAllowance(address allowed, uint256 amount) external;

    /// @notice Used for deducting the fees from the payer to the middleware
    function takeFee(address initiator, address payer, uint256 feeAmount) external;

    /**
     * @notice Modifies the `paymentChallengeAmount` amount.
     * @param _paymentChallengeAmount The new value for `paymentChallengeAmount` to take.
     */
    function setPaymentChallengeAmount(uint256 _paymentChallengeAmount) external;

    /**
     * @notice This is used by an operator to make a claim on the amount that they deserve for their service from their last payment until `toTaskNumber`
     * @dev Once this payment is recorded, a fraud proof period commences during which a challenger can dispute the proposed payment.
     */
    function commitPayment(uint32 toTaskNumber, uint96 amount) external;

    /**
     * @notice Called by an operator to redeem a payment that they previously 'committed' to by calling `commitPayment`.
     * @dev This function can only be called after the challenge window for the payment claim has completed.
     */
    function redeemPayment() external;

    /**
     * @notice This function is called by a fraud prover to challenge a payment, initiating an interactive-type fraudproof.
     * @param operator is the operator against whose payment claim the fraudproof is being made
     * @param amount1 is the reward amount the challenger in that round claims is for the first half of tasks
     * @param amount2 is the reward amount the challenger in that round claims is for the second half of tasks
     *
     */
    function initPaymentChallenge(address operator, uint96 amount1, uint96 amount2) external;

    /**
     * @notice Perform a single bisection step in an existing interactive payment challenge.
     * @param operator The middleware operator who was challenged (used to look up challenge details)
     * @param secondHalf If true, then the caller wishes to challenge the amount claimed as payment in the *second half* of the
     * previous bisection step. If false then the *first half* is indicated instead.
     * @param amount1 The amount that the caller asserts the operator is entitled to, for the first half *of the challenged half* of the previous bisection.
     * @param amount2 The amount that the caller asserts the operator is entitled to, for the second half *of the challenged half* of the previous bisection.
     */
    function performChallengeBisectionStep(address operator, bool secondHalf, uint96 amount1, uint96 amount2)
        external;

    /// @notice resolve an existing PaymentChallenge for an operator
    function resolveChallenge(address operator) external;

    /**
     * @notice Challenge window for submitting fraudproof in the case of an incorrect payment claim by a registered operator.
     */
    function paymentFraudproofInterval() external view returns (uint256);

    /**
     * @notice Specifies the payment that has to be made as a guarantee for fraudproof during payment challenges.
     */
    function paymentChallengeAmount() external view returns (uint256);

    /// @notice the ERC20 token that will be used by the disperser to pay the service fees to middleware nodes.
    function paymentToken() external view returns (IERC20);

    /// @notice Token used for placing a guarantee on challenges & payment commits
    function paymentChallengeToken() external view returns (IERC20);

    /// @notice Returns the ChallengeStatus for the `operator`'s payment claim.
    function getChallengeStatus(address operator) external view returns (ChallengeStatus);

    /// @notice Returns the 'amount1' for the `operator`'s payment claim.
    function getAmount1(address operator) external view returns (uint96);

    /// @notice Returns the 'amount2' for the `operator`'s payment claim.
    function getAmount2(address operator) external view returns (uint96);

    /// @notice Returns the 'toTaskNumber' for the `operator`'s payment claim.
    function getToTaskNumber(address operator) external view returns (uint48);

    /// @notice Returns the 'fromTaskNumber' for the `operator`'s payment claim.
    function getFromTaskNumber(address operator) external view returns (uint48);

    /// @notice Returns the task number difference for the `operator`'s payment claim.
    function getDiff(address operator) external view returns (uint48);

    /// @notice Returns the active guarantee amount of the `operator` placed on their payment claim.
    function getPaymentChallengeAmount(address) external view returns (uint256);
}
