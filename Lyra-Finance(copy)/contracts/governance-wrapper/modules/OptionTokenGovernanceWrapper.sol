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
  
  //SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

import "../BaseGovernanceWrapper.sol";
import "../../OptionToken.sol";

contract OptionTokenGovernanceWrapper is BaseGovernanceWrapper {
  struct OptionTokenBounds {
    OptionToken.PartialCollateralParameters minPartialCollatParams;
    OptionToken.PartialCollateralParameters maxPartialCollatParams;
  }

  OptionToken public optionToken;
  OptionTokenBounds internal optionTokenBounds;

  constructor() BaseGovernanceWrapper() {}

  ////////////////
  // Only Owner //
  ////////////////

  function setOptionToken(OptionToken _optionToken) external onlyOwner {
    if (address(optionToken) != address(0)) {
      revert OTGW_OptionTokenAlreadySet(optionToken);
    }
    _optionToken.acceptOwnership();
    optionToken = _optionToken;
    emit OTGW_OptionTokenSet(optionToken);
  }

  function setOptionTokenBounds(OptionTokenBounds memory _optionTokenBounds) external onlyOwner {
    optionTokenBounds = _optionTokenBounds;
    emit OTGW_OptionTokenBoundsSet(_optionTokenBounds);
  }

  function setOptionTokenURI(string memory newURI) external onlyOwner {
    optionToken.setURI(newURI);
    emit OTGW_OptionTokenURIChanged(newURI);
  }

  ///////////////////////////
  // Risk Council or Owner //
  ///////////////////////////

  function setPartialCollateralParams(
    OptionToken.PartialCollateralParameters memory _partialCollatParams
  ) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      OptionToken.PartialCollateralParameters memory lowerBound = optionTokenBounds.minPartialCollatParams;
      OptionToken.PartialCollateralParameters memory upperBound = optionTokenBounds.maxPartialCollatParams;
      if (
        _partialCollatParams.penaltyRatio < lowerBound.penaltyRatio ||
        _partialCollatParams.penaltyRatio > upperBound.penaltyRatio ||
        _partialCollatParams.liquidatorFeeRatio < lowerBound.liquidatorFeeRatio ||
        _partialCollatParams.liquidatorFeeRatio > upperBound.liquidatorFeeRatio ||
        _partialCollatParams.smFeeRatio < lowerBound.smFeeRatio ||
        _partialCollatParams.smFeeRatio > upperBound.smFeeRatio ||
        _partialCollatParams.minLiquidationFee < lowerBound.minLiquidationFee ||
        _partialCollatParams.minLiquidationFee > upperBound.minLiquidationFee
      ) {
        revert OTGW_partialCollateralParamsOutOfBounds(_partialCollatParams, msg.sender);
      }
    }
    optionToken.setPartialCollateralParams(_partialCollatParams);
    emit OTGW_PartialCollateralParamsSet(msg.sender, _partialCollatParams);
  }

  ///////////
  // Views //
  ///////////
  function getOptionTokenBounds() external view returns (OptionTokenBounds memory bounds) {
    return optionTokenBounds;
  }

  ////////////
  // Events //
  ////////////
  event OTGW_OptionTokenSet(OptionToken optionToken);
  event OTGW_OptionTokenURIChanged(string newURI);
  event OTGW_OptionTokenBoundsSet(OptionTokenBounds optionTokenBounds);
  event OTGW_PartialCollateralParamsSet(
    address indexed caller,
    OptionToken.PartialCollateralParameters partialCollatParams
  );

  ////////////
  // Errors //
  ////////////

  error OTGW_OptionTokenAlreadySet(OptionToken optionToken);
  error OTGW_partialCollateralParamsOutOfBounds(
    OptionToken.PartialCollateralParameters partialCollatParams,
    address sender
  );
}
