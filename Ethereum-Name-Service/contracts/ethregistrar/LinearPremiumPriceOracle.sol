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
  
  //SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "./SafeMath.sol";
import "./StablePriceOracle.sol";

contract LinearPremiumPriceOracle is StablePriceOracle {
    using SafeMath for *;

    uint256 immutable GRACE_PERIOD = 90 days;

    uint256 public immutable initialPremium;
    uint256 public immutable premiumDecreaseRate;

    bytes4 private constant TIME_UNTIL_PREMIUM_ID =
        bytes4(keccak256("timeUntilPremium(uint,uint"));

    constructor(
        AggregatorInterface _usdOracle,
        uint256[] memory _rentPrices,
        uint256 _initialPremium,
        uint256 _premiumDecreaseRate
    ) public StablePriceOracle(_usdOracle, _rentPrices) {
        initialPremium = _initialPremium;
        premiumDecreaseRate = _premiumDecreaseRate;
    }

    function _premium(
        string memory name,
        uint256 expires,
        uint256 /*duration*/
    ) internal view override returns (uint256) {
        expires = expires.add(GRACE_PERIOD);
        if (expires > block.timestamp) {
            // No premium for renewals
            return 0;
        }

        // Calculate the discount off the maximum premium
        uint256 discount = premiumDecreaseRate.mul(
            block.timestamp.sub(expires)
        );

        // If we've run out the premium period, return 0.
        if (discount > initialPremium) {
            return 0;
        }

        return initialPremium - discount;
    }

    /**
     * @dev Returns the timestamp at which a name with the specified expiry date will have
     *      the specified re-registration price premium.
     * @param expires The timestamp at which the name expires.
     * @param amount The amount, in wei, the caller is willing to pay
     * @return The timestamp at which the premium for this domain will be `amount`.
     */
    function timeUntilPremium(
        uint256 expires,
        uint256 amount
    ) external view returns (uint256) {
        amount = weiToAttoUSD(amount);
        require(amount <= initialPremium);

        expires = expires.add(GRACE_PERIOD);

        uint256 discount = initialPremium.sub(amount);
        uint256 duration = discount.div(premiumDecreaseRate);
        return expires.add(duration);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns (bool) {
        return
            (interfaceID == TIME_UNTIL_PREMIUM_ID) ||
            super.supportsInterface(interfaceID);
    }
}
