/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/OpenSea-Seaport?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum Method {
    BASIC,
    FULFILL,
    MATCH,
    FULFILL_AVAILABLE,
    FULFILL_ADVANCED,
    MATCH_ADVANCED,
    FULFILL_AVAILABLE_ADVANCED,
    CANCEL,
    VALIDATE,
    INCREMENT_COUNTER,
    GET_ORDER_HASH,
    GET_ORDER_STATUS,
    GET_COUNTER,
    INFORMATION,
    NAME
}

enum OrderStatusEnum {
    AVAILABLE, // not validated or fulfilled; implicitly validated via signature except when match is called
    VALIDATED, // validated on-chain
    PARTIAL, // partially fulfilled
    FULFILLED, // completely fulfilled
    CANCELLED_EXPLICIT, // explicit cancellation
    CANCELLED_COUNTER, // canceled via counter increment (reverts due to invalid sig)
    REVERT // fulfilling reverts
}

enum BroadOrderType {
    FULL,
    PARTIAL,
    CONTRACT
}

// !BroadOrderType.CONTRACT <- Zone
enum Zone {
    NONE,
    PASS,
    FAIL
}

// !BroadOrderType.CONTRACT <- OrderAuth
enum NumOrders {
    ONE,
    MULTIPLE
}

// NumOrders.MULTIPLE && any(OrderFulfillment.PARTIAL) <- OrderComposition
enum OrdersComposition {
    HOMOGENOUS,
    HETEROGENOUS
}

// OrderStatus.REVERT && !Zone.FAIL && !Offerer.CONTRACT_OFFERER <- OrderStatusRevertReason
enum OrderStatusRevertReason {
    NATIVE, // receive hook fails
    ERC1155 // receive hook fails
}

// ItemType.ERC20/ERC1155/ERC721 <- TokenIndex
// (test contracts have 3 of each token deployed; can mix and match)
enum TokenIndex {
    ONE,
    TWO,
    THREE
}

enum Criteria {
    MERKLE, // non-zero criteria
    WILDCARD // criteria zero
}

// Criteria.WILDCARD/MERKLE <- CriteriaResolved
enum CriteriaResolved {
    VALID, // correctly resolved
    INVALID, // incorrectly resolved
    UNAVAILABLE // resolved but not owned/approved
}

enum Amount {
    FIXED,
    ASCENDING,
    DESCENDING
}

enum AmountDegree {
    // ZERO, ?
    SMALL,
    MEDIUM,
    LARGE,
    WUMBO
}

enum FulfillmentRecipient {
    ZERO,
    ALICE,
    BOB,
    EVE
}

// ConsiderationItem.* / ReceivedItem.* / Method.*ADVANCED <- Recipient
enum Recipient {
    // ZERO,?
    OFFERER,
    RECIPIENT,
    DILLON,
    EVE,
    FRANK
    // INVALID
}

enum RecipientDirty {
    CLEAN,
    DIRTY
}

enum Caller {
    TEST_CONTRACT,
    ALICE,
    BOB,
    CAROL,
    DILLON,
    EVE,
    FRANK
}

// disregarded in the self_ad_hoc case
enum Offerer {
    TEST_CONTRACT,
    ALICE, // consider EOA space enum
    BOB,
    CONTRACT_OFFERER,
    EIP1271
}

// debatable if needed but we do need to test zonehash permutations
enum ZoneHash {
    NONE,
    VALID,
    INVALID
}

// Offerer.CONTRACT_OFFERER <- ContractOfferer
enum ContractOfferer {
    PASS,
    FAIL_GENERATE,
    FAIL_MIN_RECEIVED,
    FAIL_MAX_SPENT,
    FAIL_RATIFY
}

// ContractOfferer.PASS <- ContractOffererPassGenerated
enum ContractOffererPassGenerated {
    IDENTITY,
    MIN_RECEIVED,
    MAX_SPENT,
    BOTH
}

// ContractOffererPassGenerated.MIN_RECEIVED/BOTH <- ContractOffererPassMinReceived
enum ContractOffererPassMinReceived {
    MORE_MIN_RECEIVED,
    EXTRA_MIN_RECEIVED,
    BOTH
}

// ContractOffererPassGenerated.MAX_SPENT/BOTH <- ContractOffererPassMaxSpent
enum ContractOffererPassMaxSpent {
    LESS_MAX_SPENT,
    TRUNCATED_MAX_SPENT,
    BOTH
}

enum ContractOffererFailGenerated {
    MIN_RECEIVED,
    MAX_SPENT,
    BOTH
}

// ContractOffererFailGenerated.MIN_RECEIVED/BOTH <- ContractOffererFailMinReceived
enum ContractOffererFailMinReceived {
    LESS_MIN_RECEIVED,
    TRUNCATED_MIN_RECEIVED,
    BOTH
}

// ContractOffererFailGenerated.MAX_SPENT/BOTH <- ContractOffererFailMaxSpent
enum ContractOffererFailMaxSpent {
    MORE_MAX_SPENT,
    EXTRA_MAX_SPENT,
    BOTH
}

enum Time {
    // valid granularity important for ascending/descending
    STARTS_IN_FUTURE,
    EXACT_START, // order is live
    ONGOING,
    EXACT_END, // order is expired
    EXPIRED
}

// Method.MATCH* <- MatchValidation
enum MatchValidation {
    SELF_AD_HOC,
    SIGNATURE
}

enum SignatureMethod {
    EOA,
    VALIDATE,
    EIP1271,
    CONTRACT,
    SELF_AD_HOC
}

// Offerer.EOA <- EOASignature
enum EOASignature {
    STANDARD,
    EIP2098,
    BULK,
    BULK2098
}

// Offerer.EIP1271 <- EIP1271Signature
enum EIP1271Signature {
    EIP1271,
    EIP1271_BULKLIKE
}

// Validation.SIGNATURE <- SignatureValidity
enum SignatureValidity {
    VALID,
    INVALID
}

// EOASignature.BULK/BULK2098+EIP1271Signature.EIP1271_BULKLIKE <- BulkSignatureSize
enum BulkSignatureSize {
    ONE,
    TWO,
    THREE,
    FOUR,
    FIVE,
    SIX,
    SEVEN,
    EIGHT,
    NINE,
    TEN,
    ELEVEN,
    TWELVE,
    THIRTEEN,
    FOURTEEN,
    FIFTEEN,
    SIXTEEN,
    SEVENTEEN,
    EIGHTEEN,
    NINETEEN,
    TWENTY,
    TWENTYONE,
    TWENTYTWO,
    TWENTYTHREE,
    TWENTYFOUR
}

enum Salt {
    VALID,
    DUPLICATE // ?
}

enum ConduitChoice {
    NONE,
    ONE,
    TWO
}

enum Counter {
    VALID,
    INVALID
}

// Counter.INVALID <- CounterValue
enum CounterValue {
    LESS,
    GREATER
}

enum TotalOriginalConsiderationItems {
    LESS,
    EQUAL,
    GREATER
}

// Method.*Advanced <- Fraction
enum Fraction {
    INVALID,
    VALID
}

// Fraction.VALID <- ValidFraction
enum ValidFraction {
    SMALL,
    HALF,
    LARGE,
    WHOLE
}

enum InvalidFraction {
    INVALID, // order is a full order
    UNEVEN, // cannot divide into amount
    IRREGULAR // N/M where N > M
}

enum CriteriaProofs {
    LESS, // too few proofs
    EQUAL, // sufficient number of proofs
    GREATER // extra proofs
}

// Method.FULFILL_AVAILABLE* <= FulfillAvailableFulfillments
enum FulfillAvailableFulfillments {
    NAIVE, // one component per offer + consideration item, ie, unaggregated
    AGGREGATED,
    INVALID
}

// FulfillAvailableFulfillments.INVALID <- InvalidFulfillAvailableFulfillments
enum InvalidFulfillAvailableFulfillments {
    OFFER,
    CONSIDERATION,
    BOTH
}

// InvalidFulfillAvailableFulfillments.* <- InvalidFulfillAvailableFulfillmentsCondition
enum InvalidFulfillAvailableFulfillmentsCondition {
    INVALID, // ie not correctly constructed, duplicates, etc
    LESS, // ie missing fulfillments
    GREATER // ie including duplicates
}

// FulfillAvailableFulfillments.AGGREGATED <- AggregatedFulfillAvailableFulfillments
enum AggregatedFulfillAvailableFulfillments {
    OFFER,
    CONSIDERATION,
    BOTH
}

enum BasicOrderCategory {
    NONE,
    LISTING,
    BID
}

enum Tips {
    NONE,
    TIPS
}

enum UnavailableReason {
    AVAILABLE,
    EXPIRED,
    STARTS_IN_FUTURE,
    CANCELLED,
    ALREADY_FULFILLED,
    MAX_FULFILLED_SATISFIED,
    GENERATE_ORDER_FAILURE
}

enum ExtraData {
    NONE,
    RANDOM
}

enum ContractOrderRebate {
    NONE,
    MORE_OFFER_ITEMS,
    MORE_OFFER_ITEM_AMOUNTS,
    LESS_CONSIDERATION_ITEMS,
    LESS_CONSIDERATION_ITEM_AMOUNTS
}
