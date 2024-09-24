/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Lyra-Finance?utm=code
  */
  
  pragma solidity ^0.8.0;

/*
  copied from https://github.com/pyth-network/pyth-sdk-solidity/blob/main/MockPyth.sol
  and adjusted to compile with solidity ^0.5.16
*/
contract PythStructs {
  // A price with a degree of uncertainty, represented as a price +- a confidence interval.
  //
  // The confidence interval roughly corresponds to the standard error of a normal distribution.
  // Both the price and confidence are stored in a fixed-point numeric representation,
  // `x * (10^expo)`, where `expo` is the exponent.
  //
  // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
  // to how this price safely.
  struct Price {
    // Price
    int64 price;
    // Confidence interval around the price
    uint64 conf;
    // Price exponent
    int32 expo;
    // Unix timestamp describing when the price was published
    uint publishTime;
  }

  // PriceFeed represents a current aggregate price from pyth publisher feeds.
  struct PriceFeed {
    // The price ID.
    bytes32 id;
    // Latest available price
    Price price;
    // Latest available exponentially-weighted moving average price
    Price emaPrice;
  }
}

contract MockPyth {
  mapping(bytes32 => PythStructs.PriceFeed) private priceFeeds;
  uint64 private sequenceNumber;

  uint private singleUpdateFeeInWei;
  uint private validTimePeriod;

  constructor(uint _validTimePeriod, uint _singleUpdateFeeInWei) public {
    singleUpdateFeeInWei = _singleUpdateFeeInWei;
    validTimePeriod = _validTimePeriod;
  }

  event PriceFeedUpdate(
    bytes32 indexed id,
    bool indexed fresh,
    uint16 chainId,
    uint64 sequenceNumber,
    uint lastPublishTime,
    uint publishTime,
    int64 price,
    uint64 conf
  );

  event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber, uint batchSize, uint freshPricesInBatch);

  event UpdatePriceFeeds(address indexed sender, uint batchCount, uint fee);

  function mockUpdateFee(uint newSingleUpdateFeeInWei) external {
    singleUpdateFeeInWei = newSingleUpdateFeeInWei;
  }

  function mockUpdateValidTimePeriod(uint newValidTimePeriod) external {
    validTimePeriod = newValidTimePeriod;
  }

  function getPrice(bytes32 id) external view returns (PythStructs.Price memory price) {
    return getPriceNoOlderThan(id, getValidTimePeriod());
  }

  function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price) {
    return getEmaPriceNoOlderThan(id, getValidTimePeriod());
  }

  function getPriceUnsafe(bytes32 id) public view returns (PythStructs.Price memory price) {
    PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
    return priceFeed.price;
  }

  function getPriceNoOlderThan(bytes32 id, uint age) public view returns (PythStructs.Price memory price) {
    price = getPriceUnsafe(id);

    require(diff(block.timestamp, price.publishTime) <= age, "no price available which is recent enough");

    return price;
  }

  function getEmaPriceUnsafe(bytes32 id) public view returns (PythStructs.Price memory price) {
    PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
    return priceFeed.emaPrice;
  }

  function getEmaPriceNoOlderThan(bytes32 id, uint age) public view returns (PythStructs.Price memory price) {
    price = getEmaPriceUnsafe(id);

    require(diff(block.timestamp, price.publishTime) <= age, "no ema price available which is recent enough");

    return price;
  }

  function diff(uint x, uint y) internal pure returns (uint) {
    if (x > y) {
      return x - y;
    } else {
      return y - x;
    }
  }

  function updatePriceFeedsIfNecessary(
    bytes[] calldata updateData,
    bytes32[] calldata priceIds,
    uint64[] calldata publishTimes
  ) external payable {
    require(priceIds.length == publishTimes.length, "priceIds and publishTimes arrays should have same length");

    bool updateNeeded = false;
    for (uint i = 0; i < priceIds.length; i++) {
      if (!priceFeedExists(priceIds[i]) || queryPriceFeed(priceIds[i]).price.publishTime < publishTimes[i]) {
        updateNeeded = true;
        break;
      }
    }

    require(updateNeeded, "no prices in the submitted batch have fresh prices, so this update will have no effect");

    bytes[] memory updateDataInt = new bytes[](updateData.length);
    for (uint i = 0; i < updateData.length; i++) {
      updateDataInt[i] = updateData[i];
    }
    _updatePriceFeeds(updateDataInt);
  }

  function queryPriceFeed(bytes32 id) public view returns (PythStructs.PriceFeed memory priceFeed) {
    require(priceFeeds[id].id != 0, "no price feed found for the given price id");
    return priceFeeds[id];
  }

  function priceFeedExists(bytes32 id) public view returns (bool) {
    return (priceFeeds[id].id != 0);
  }

  function getValidTimePeriod() public view returns (uint) {
    return validTimePeriod;
  }

  // Takes an array of encoded price feeds and stores them.
  // You can create this data either by calling createPriceFeedData or
  // by using web3.js or ethers abi utilities.
  function updatePriceFeeds(bytes[] calldata updateData) external payable {
    bytes[] memory updateDataInt = new bytes[](updateData.length);
    for (uint i = 0; i < updateData.length; i++) {
      updateDataInt[i] = updateData[i];
    }
    _updatePriceFeeds(updateDataInt);
  }

  function _updatePriceFeeds(bytes[] memory updateData) internal {
    uint requiredFee = getUpdateFee(updateData);
    require(msg.value >= requiredFee, "Insufficient paid fee amount");

    if (msg.value > requiredFee) {
      // solhint-disable-next-line  avoid-low-level-calls
      (bool success, ) = msg.sender.call{value: (msg.value - requiredFee)}("");
      require(success, "failed to transfer update fee");
    }

    uint freshPrices = 0;

    // Chain ID is id of the source chain that the price update comes from. Since it is just a mock contract
    // We set it to 1.
    uint16 chainId = 1;

    for (uint i = 0; i < updateData.length; i++) {
      PythStructs.PriceFeed memory priceFeed = abi.decode(updateData[i], (PythStructs.PriceFeed));

      bool fresh = false;
      uint lastPublishTime = priceFeeds[priceFeed.id].price.publishTime;

      if (lastPublishTime < priceFeed.price.publishTime) {
        // Price information is more recent than the existing price information.
        fresh = true;
        priceFeeds[priceFeed.id] = priceFeed;
        freshPrices += 1;
      }

      emit PriceFeedUpdate(
        priceFeed.id,
        fresh,
        chainId,
        sequenceNumber,
        priceFeed.price.publishTime,
        lastPublishTime,
        priceFeed.price.price,
        priceFeed.price.conf
      );
    }

    // In the real contract, the input of this function contains multiple batches that each contain multiple prices.
    // This event is emitted when a batch is processed. In this mock contract we consider there is only one batch of prices.
    // Each batch has (chainId, sequenceNumber) as it's unique identifier. Here chainId is set to 1 and an increasing sequence number is used.
    emit BatchPriceFeedUpdate(chainId, sequenceNumber, updateData.length, freshPrices);
    sequenceNumber += 1;

    // There is only 1 batch of prices
    emit UpdatePriceFeeds(msg.sender, 1, requiredFee);
  }

  function getUpdateFee(bytes[] memory updateData) public view returns (uint feeAmount) {
    return singleUpdateFeeInWei * updateData.length;
  }

  function createPriceFeedUpdateData(
    bytes32 id,
    int64 price,
    uint64 conf,
    int32 expo,
    int64 emaPrice,
    uint64 emaConf,
    uint64 publishTime
  ) external pure returns (bytes memory priceFeedData) {
    PythStructs.PriceFeed memory priceFeed;

    priceFeed.id = id;

    priceFeed.price.price = price;
    priceFeed.price.conf = conf;
    priceFeed.price.expo = expo;
    priceFeed.price.publishTime = publishTime;

    priceFeed.emaPrice.price = emaPrice;
    priceFeed.emaPrice.conf = emaConf;
    priceFeed.emaPrice.expo = expo;
    priceFeed.emaPrice.publishTime = publishTime;

    priceFeedData = abi.encode(priceFeed);
  }
}
