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

import "Eigenlayer/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "Eigenlayer/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "Eigenlayer/lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IServiceManager.sol";
import "../interfaces/IQuorumRegistry.sol";
import "../interfaces/IDelegationManager.sol";
import "../interfaces/IPaymentManager.sol";
import "../permissions/Pausable.sol";

/**
 * @title Controls 'rolled-up' middleware payments.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 * @notice This contract is used for doing interactive payment challenges.
 * @notice The contract is marked as abstract since it does not implement the `respondToPaymentChallengeFinal`
 * function -- see DataLayerPaymentManager for an example
 */
//
abstract contract PaymentManager is Initializable, IPaymentManager, Pausable {
    using SafeERC20 for IERC20;

    uint8 constant internal PAUSED_NEW_PAYMENT_COMMIT = 0;
    uint8 constant internal PAUSED_REDEEM_PAYMENT = 1;

    // DATA STRUCTURES

    /**
     * @notice Challenge window for submitting fraudproof in the case of an incorrect payment claim by a registered operator.
     */
    uint256 public constant paymentFraudproofInterval = 7 days;
    /// @notice Constant used as a divisor in dealing with BIPS amounts
    uint256 internal constant MAX_BIPS = 10000;

    /**
     * @notice The global EigenLayer Delegation contract, which is primarily used by
     * stakers to delegate their stake to operators who serve as middleware nodes.
     * @dev For more details, see DelegationManager.sol.
     */
    IDelegationManager public immutable delegationManager;

    /// @notice The ServiceManager contract for this middleware, where tasks are created / initiated.
    IServiceManager public immutable serviceManager;

    /// @notice The Registry contract for this middleware, where operators register and deregister.
    IQuorumRegistry public immutable registry;

    /// @notice the ERC20 token that will be used by the disperser to pay the service fees to middleware nodes.
    IERC20 public immutable paymentToken;

    /// @notice Token used for placing a guarantee on challenges & payment commits
    IERC20 public immutable paymentChallengeToken;

    /**
     * @notice Specifies the payment that has to be made as a guarantee for fraudproof during payment challenges.
     */
    uint256 public paymentChallengeAmount;

    /// @notice mapping between the operator and its current committed payment or last redeemed payment
    mapping(address => Payment) public operatorToPayment;

    /// @notice mapping from operator => PaymentChallenge
    mapping(address => PaymentChallenge) public operatorToPaymentChallenge;

    /// @notice Deposits of future fees to be drawn against when paying for service from the middleware
    mapping(address => uint256) public depositsOf;

    /// @notice depositors => addresses approved to spend deposits => allowance
    mapping(address => mapping(address => uint256)) public allowances;

    // EVENTS
    /// @notice Emitted when the `paymentChallengeAmount` variable is modified
    event PaymentChallengeAmountSet(uint256 previousValue, uint256 newValue);

    /// @notice Emitted when an operator commits to a payment by calling the `commitPayment` function
    event PaymentCommit(address operator, uint32 fromTaskNumber, uint32 toTaskNumber, uint256 fee);

    /// @notice Emitted when a new challenge is created through a call to the `initPaymentChallenge` function
    event PaymentChallengeInit(address indexed operator, address challenger);

    /// @notice Emitted when an operator redeems a payment by calling the `redeemPayment` function
    event PaymentRedemption(address indexed operator, uint256 fee);

    /// @notice Emitted when a bisection step is performed in a challenge, through a call to the `performChallengeBisectionStep` function
    event PaymentBreakdown(
        address indexed operator, uint32 fromTaskNumber, uint32 toTaskNumber, uint96 amount1, uint96 amount2
    );

    /// @notice Emitted upon successful resolution of a payment challenge, within a call to `resolveChallenge`
    event PaymentChallengeResolution(address indexed operator, bool operatorWon);

    /// @notice when applied to a function, ensures that the function is only callable by the `serviceManager`
    modifier onlyServiceManager() {
        require(msg.sender == address(serviceManager), "onlyServiceManager");
        _;
    }

    /// @notice when applied to a function, ensures that the function is only callable by the `registry`
    modifier onlyRegistry() {
        require(msg.sender == address(registry), "onlyRegistry");
        _;
    }

    /// @notice when applied to a function, ensures that the function is only callable by the owner of the `serviceManager`
    modifier onlyServiceManagerOwner() {
        require(msg.sender == serviceManager.owner(), "onlyServiceManagerOwner");
        _;
    }

    constructor(
        IDelegationManager _delegationManager,
        IServiceManager _serviceManager,
        IQuorumRegistry _registry,
        IERC20 _paymentToken,
        IERC20 _paymentChallengeToken
    ) {
        delegationManager = _delegationManager;
        serviceManager = _serviceManager;
        registry = _registry;
        paymentToken = _paymentToken;
        paymentChallengeToken = _paymentChallengeToken;
        _disableInitializers();
    }

    function initialize(IPauserRegistry _pauserReg, uint256 _paymentChallengeAmount) public initializer {
        _initializePauser(_pauserReg, UNPAUSE_ALL);
        _setPaymentChallengeAmount(_paymentChallengeAmount);
    }

    /**
     * @notice deposit one-time fees by the `msg.sender` with this contract to pay for future tasks of this middleware
     * @param depositFor could be the `msg.sender` themselves, or a different address for whom `msg.sender` is depositing these future fees
     * @param amount is amount of futures fees being deposited
     */
    function depositFutureFees(address depositFor, uint256 amount) external {
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        depositsOf[depositFor] += amount;
    }

    /// @notice Allows the `allowed` address to spend up to `amount` of the `msg.sender`'s funds that have been deposited in this contract
    function setAllowance(address allowed, uint256 amount) external {
        allowances[msg.sender][allowed] = amount;
    }

    /**
     * @notice Modifies the `paymentChallengeAmount` amount.
     * @param _paymentChallengeAmount The new value for `paymentChallengeAmount` to take.
     */
    function setPaymentChallengeAmount(uint256 _paymentChallengeAmount) external virtual onlyServiceManagerOwner {
        _setPaymentChallengeAmount(_paymentChallengeAmount);
    }

    /// @notice Used for deducting the fees from the payer to the middleware
    function takeFee(address initiator, address payer, uint256 feeAmount) external virtual onlyServiceManager {
        if (initiator != payer) {
            if (allowances[payer][initiator] != type(uint256).max) {
                allowances[payer][initiator] -= feeAmount;
            }
        }

        // decrement `payer`'s stored deposits
        depositsOf[payer] -= feeAmount;
    }

    /**
     * @notice This is used by an operator to make a claim on the amount that they deserve for their service from their last payment until `toTaskNumber`
     * @dev Once this payment is recorded, a fraud proof period commences during which a challenger can dispute the proposed payment.
     */
    function commitPayment(uint32 toTaskNumber, uint96 amount) external onlyWhenNotPaused(PAUSED_NEW_PAYMENT_COMMIT) {
        // only active operators can call
        require(
            registry.isActiveOperator(msg.sender),
            "PaymentManager.commitPayment: Only registered operators can call this function"
        );

        require(toTaskNumber <= _taskNumber(), "PaymentManager.commitPayment: Cannot claim future payments");

        // can only claim for a payment after redeeming the last payment
        require(
            operatorToPayment[msg.sender].status == PaymentStatus.REDEEMED,
            "PaymentManager.commitPayment: Require last payment is redeemed"
        );

        // operator puts up tokens which can be slashed in case of wrongful payment claim
        paymentChallengeToken.safeTransferFrom(msg.sender, address(this), paymentChallengeAmount);

        // recording payment claims for the operator
        uint32 fromTaskNumber;

        // calculate the UTC timestamp at which the payment claim will be optimistically confirmed
        uint32 confirmAt = uint32(block.timestamp + paymentFraudproofInterval);

        /**
         * @notice For the special case of this being the first payment that is being claimed by the operator,
         * the operator must be claiming payment starting from when they registered.
         */
        if (operatorToPayment[msg.sender].fromTaskNumber == 0) {
            // get the taskNumber when the operator registered
            fromTaskNumber = registry.getFromTaskNumberForOperator(msg.sender);
        } else {
            // you have to redeem starting from the last task you previously redeemed up to
            fromTaskNumber = operatorToPayment[msg.sender].toTaskNumber;
        }

        require(fromTaskNumber < toTaskNumber, "invalid payment range");

        // update the record for the commitment to payment made by the operator
        operatorToPayment[msg.sender] = Payment(
            fromTaskNumber,
            toTaskNumber,
            confirmAt,
            amount,
            // set payment status as 1: committed
            PaymentStatus.COMMITTED,
            // storing guarantee amount deposited
            paymentChallengeAmount
        );

        emit PaymentCommit(msg.sender, fromTaskNumber, toTaskNumber, amount);
    }

    /**
     * @notice Called by an operator to redeem a payment that they previously 'committed' to by calling `commitPayment`.
     * @dev This function can only be called after the challenge window for the payment claim has completed.
     */
    function redeemPayment() external onlyWhenNotPaused(PAUSED_REDEEM_PAYMENT) {
        // verify that the `msg.sender` has a committed payment
        require(
            operatorToPayment[msg.sender].status == PaymentStatus.COMMITTED,
            "PaymentManager.redeemPayment: Payment Status is not 'COMMITTED'"
        );

        // check that the fraudproof period has already transpired
        require(
            block.timestamp > operatorToPayment[msg.sender].confirmAt,
            "PaymentManager.redeemPayment: Payment still eligible for fraudproof"
        );

        // update the status to show that operator's payment is getting redeemed
        operatorToPayment[msg.sender].status = PaymentStatus.REDEEMED;

        // Transfer back the challengeAmount to the operator as there was no successful challenge to the payment commitment made by the operator.
        paymentChallengeToken.safeTransfer(msg.sender, operatorToPayment[msg.sender].challengeAmount);

        // look up payment amount and earnings receiver address for the `msg.sender`
        uint256 amount = operatorToPayment[msg.sender].amount;
        address earningsReceiver = delegationManager.earningsReceiver(msg.sender);

        // transfer the amount due in the payment claim of the operator to its earnings receiver address, where the delegators can withdraw their rewards.
        paymentToken.safeTransfer(earningsReceiver, amount);

        // emit event
        emit PaymentRedemption(msg.sender, amount);
    }

    /**
     * @notice This function is called by a fraud prover to challenge a payment, initiating an interactive-type fraudproof.
     * @param operator is the operator against whose payment claim the fraudproof is being made
     * @param amount1 is the reward amount the challenger in that round claims is for the first half of tasks
     * @param amount2 is the reward amount the challenger in that round claims is for the second half of tasks
     *
     */
    function initPaymentChallenge(address operator, uint96 amount1, uint96 amount2) external {
        require(
            block.timestamp < operatorToPayment[operator].confirmAt
                && operatorToPayment[operator].status == PaymentStatus.COMMITTED,
            "PaymentManager.initPaymentChallenge: Fraudproof interval has passed for payment"
        );

        // store challenge details
        operatorToPaymentChallenge[operator] = PaymentChallenge(
            operator,
            msg.sender,
            address(serviceManager),
            operatorToPayment[operator].fromTaskNumber,
            operatorToPayment[operator].toTaskNumber,
            amount1,
            amount2,
            // recording current timestamp plus the fraudproof interval as the `settleAt` timestamp for this challenge
            uint32(block.timestamp + paymentFraudproofInterval),
            // set the status for the operator to respond next
            ChallengeStatus.OPERATOR_TURN
        );

        // move challengeAmount over
        uint256 challengeAmount = operatorToPayment[operator].challengeAmount;
        paymentChallengeToken.safeTransferFrom(msg.sender, address(this), challengeAmount);
        // update the payment status and reset the fraudproof window for this payment
        operatorToPayment[operator].status = PaymentStatus.CHALLENGED;
        operatorToPayment[operator].confirmAt = uint32(block.timestamp + paymentFraudproofInterval);
        emit PaymentChallengeInit(operator, msg.sender);
    }

    /**
     * @notice Perform a single bisection step in an existing interactive payment challenge.
     * @param operator The middleware operator who was challenged (used to look up challenge details)
     * @param secondHalf If true, then the caller wishes to challenge the amount claimed as payment in the *second half* of the
     * previous bisection step. If false then the *first half* is indicated instead.
     * @param amount1 The amount that the caller asserts the operator is entitled to, for the first half *of the challenged half* of the previous bisection.
     * @param amount2 The amount that the caller asserts the operator is entitled to, for the second half *of the challenged half* of the previous bisection.
     */
    function performChallengeBisectionStep(address operator, bool secondHalf, uint96 amount1, uint96 amount2)
        external
    {
        // copy challenge struct to memory
        PaymentChallenge memory challenge = operatorToPaymentChallenge[operator];

        ChallengeStatus status = challenge.status;

        require(
            (status == ChallengeStatus.CHALLENGER_TURN && challenge.challenger == msg.sender)
                || (status == ChallengeStatus.OPERATOR_TURN && challenge.operator == msg.sender),
            "PaymentManager.performChallengeBisectionStep: Must be challenger and their turn or operator and their turn"
        );

        require(
            block.timestamp < challenge.settleAt,
            "PaymentManager.performChallengeBisectionStep: Challenge has already settled"
        );

        uint32 fromTaskNumber = challenge.fromTaskNumber;
        uint32 toTaskNumber = challenge.toTaskNumber;
        uint32 diff = (toTaskNumber - fromTaskNumber) / 2;

        /**
         * @notice Change the challenged interval to the one the challenger cares about.
         * If the difference between the current start and end is even, then the new interval has an endpoint halfway in-between
         * If the difference is odd = 2n + 1, the new interval has a "from" endpoint at (start + n = end - (n + 1)) if the second half is challenged,
         * or a "to" endpoint at (end - (2n + 2)/2 = end - (n + 1) = start + n) if the first half is challenged
         * In other words, it's simple when the difference is even, and when the difference is odd, we just always make the first half the smaller one.
         */
        if (secondHalf) {
            challenge.fromTaskNumber = fromTaskNumber + diff;
            _updateChallengeAmounts(operator, DissectionType.SECOND_HALF, amount1, amount2);
        } else {
            challenge.toTaskNumber = fromTaskNumber + diff;
            _updateChallengeAmounts(operator, DissectionType.FIRST_HALF, amount1, amount2);
        }

        // update who must respond next to the challenge
        _updateStatus(operator, diff);

        // extend the settlement time for the challenge, giving the next participant in the interactive fraudproof `paymentFraudproofInterval` to respond
        challenge.settleAt = uint32(block.timestamp + paymentFraudproofInterval);

        // update challenge struct in storage
        operatorToPaymentChallenge[operator] = challenge;

        emit PaymentBreakdown(
            operator, challenge.fromTaskNumber, challenge.toTaskNumber, challenge.amount1, challenge.amount2
            );
    }

    /**
     * @notice This function is used for updating the status of the challenge in terms of who has to respon
     * to the interactive challenge mechanism next -  is it going to be challenger or the operator.
     * @param operator is the operator whose payment claim is being challenged
     * @param diff is the number of tasks across which payment is being challenged in this iteration
     * @dev If the challenge is over only one task, then the challenge is marked specially as a one step challenge –
     * the smallest unit over which a challenge can be proposed – and 'true' is returned.
     * Otherwise status is updated normally and 'false' is returned.
     */
    function _updateStatus(address operator, uint32 diff) internal returns (bool) {
        // payment challenge for one task
        if (diff == 1) {
            //set to one step turn of either challenger or operator
            operatorToPaymentChallenge[operator].status =
                msg.sender == operator
                ? ChallengeStatus.CHALLENGER_TURN_ONE_STEP
                : ChallengeStatus.OPERATOR_TURN_ONE_STEP;
            return false;

        // payment challenge across more than one task
        } else {
            // set to dissection turn of either challenger or operator
            operatorToPaymentChallenge[operator].status =
                msg.sender == operator ? ChallengeStatus.CHALLENGER_TURN : ChallengeStatus.OPERATOR_TURN;
            return true;
        }
    }

    /// @notice Used to update challenge amounts when the operator (or challenger) breaks down the challenged amount (single bisection step)
    function _updateChallengeAmounts(address operator, DissectionType dissectionType, uint96 amount1, uint96 amount2)
        internal
    {
        if (dissectionType == DissectionType.FIRST_HALF) {
            // if first half is challenged, break the first half of the payment into two halves
            require(
                amount1 + amount2 != operatorToPaymentChallenge[operator].amount1,
                "PaymentManager._updateChallengeAmounts: Invalid amount breakdown"
            );
        } else if (dissectionType == DissectionType.SECOND_HALF) {
            // if second half is challenged, break the second half of the payment into two halves
            require(
                amount1 + amount2 != operatorToPaymentChallenge[operator].amount2,
                "PaymentManager._updateChallengeAmounts: Invalid amount breakdown"
            );
        } else {
            revert("PaymentManager._updateChallengeAmounts: invalid DissectionType");
        }
        // update the stored payment halves
        operatorToPaymentChallenge[operator].amount1 = amount1;
        operatorToPaymentChallenge[operator].amount2 = amount2;
    }

    /// @notice resolve an existing PaymentChallenge for an operator
    function resolveChallenge(address operator) external {
        // copy challenge struct to memory
        PaymentChallenge memory challenge = operatorToPaymentChallenge[operator];

        require(
            block.timestamp > challenge.settleAt,
            "PaymentManager.resolveChallenge: challenge has not yet reached settlement time"
        );
        ChallengeStatus status = challenge.status;
        // if operator did not respond
        if (status == ChallengeStatus.OPERATOR_TURN || status == ChallengeStatus.OPERATOR_TURN_ONE_STEP) {
            _resolve(challenge, challenge.challenger);
            // if challenger did not respond
        } else if (status == ChallengeStatus.CHALLENGER_TURN || status == ChallengeStatus.CHALLENGER_TURN_ONE_STEP) {
            _resolve(challenge, challenge.operator);
        }
    }

    /**
     * @notice Resolves a single payment challenge, paying the winner.
     * @param challenge The challenge that is being resolved.
     * @param winner Address of the winner of the challenge.
     * @dev If challenger is proven correct, then they are refunded their own challengeAmount plus the challengeAmount put up by the operator.
     * If operator is proven correct, then the challenger's challengeAmount is transferred to them, since the operator still hasn't been
     * proven right, and thus their challengeAmount is still required in case they are challenged again.
     */
    function _resolve(PaymentChallenge memory challenge, address winner) internal {
        address operator = challenge.operator;
        address challenger = challenge.challenger;
        if (winner == operator) {
            // operator was correct, allow for another challenge
            operatorToPayment[operator].status = PaymentStatus.COMMITTED;
            operatorToPayment[operator].confirmAt = uint32(block.timestamp + paymentFraudproofInterval);
            /*
            * Since the operator hasn't been proved right (only challenger has been proved wrong)
            * transfer them only challengers challengeAmount, not their own challengeAmount (which is still
            * locked up in this contract)
             */
            paymentChallengeToken.safeTransfer(operator, operatorToPayment[operator].challengeAmount);
            emit PaymentChallengeResolution(operator, true);
        } else {
            // challeger was correct, reset payment
            operatorToPayment[operator].status = PaymentStatus.REDEEMED;
            //give them their challengeAmount and the operator's
            paymentChallengeToken.safeTransfer(challenger, 2 * operatorToPayment[operator].challengeAmount);
            emit PaymentChallengeResolution(operator, false);
        }
    }

    /// @notice Returns the ChallengeStatus for the `operator`'s payment claim.
    function getChallengeStatus(address operator) external view returns (ChallengeStatus) {
        return operatorToPaymentChallenge[operator].status;
    }

    /// @notice Returns the 'amount1' for the `operator`'s payment claim.
    function getAmount1(address operator) external view returns (uint96) {
        return operatorToPaymentChallenge[operator].amount1;
    }

    /// @notice Returns the 'amount2' for the `operator`'s payment claim.
    function getAmount2(address operator) external view returns (uint96) {
        return operatorToPaymentChallenge[operator].amount2;
    }

    /// @notice Returns the 'toTaskNumber' for the `operator`'s payment claim.
    function getToTaskNumber(address operator) external view returns (uint48) {
        return operatorToPaymentChallenge[operator].toTaskNumber;
    }

    /// @notice Returns the 'fromTaskNumber' for the `operator`'s payment claim.
    function getFromTaskNumber(address operator) external view returns (uint48) {
        return operatorToPaymentChallenge[operator].fromTaskNumber;
    }

    /// @notice Returns the task number difference for the `operator`'s payment claim.
    function getDiff(address operator) external view returns (uint48) {
        return operatorToPaymentChallenge[operator].toTaskNumber - operatorToPaymentChallenge[operator].fromTaskNumber;
    }

    /// @notice Returns the active challengeAmount of the `operator` placed on their payment claim.
    function getPaymentChallengeAmount(address operator) external view returns (uint256) {
        return operatorToPayment[operator].challengeAmount;
    }

    /// @notice Convenience function for fetching the current taskNumber from the `serviceManager`
    function _taskNumber() internal view returns (uint32) {
        return serviceManager.taskNumber();
    }

    /**
     * @notice Modifies the `paymentChallengeAmount` amount.
     * @param _paymentChallengeAmount The new value for `paymentChallengeAmount` to take.
     */
    function _setPaymentChallengeAmount(uint256 _paymentChallengeAmount) internal {
        emit PaymentChallengeAmountSet(paymentChallengeAmount, _paymentChallengeAmount);
        paymentChallengeAmount = _paymentChallengeAmount;
    }
}
