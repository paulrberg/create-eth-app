/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Aave-V3?utm=code
  */
  
  // SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Errors} from '../libraries/helpers/Errors.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IPriceOracleSentinel} from '../../interfaces/IPriceOracleSentinel.sol';
import {ISequencerOracle} from '../../interfaces/ISequencerOracle.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';

/**
 * @title PriceOracleSentinel
 * @author Aave
 * @notice It validates if operations are allowed depending on the PriceOracle health.
 * @dev Once the PriceOracle gets up after an outage/downtime, users can make their positions healthy during a grace
 *  period. So the PriceOracle is considered completely up once its up and the grace period passed.
 */
contract PriceOracleSentinel is IPriceOracleSentinel {
  /**
   * @dev Only pool admin can call functions marked by this modifier.
   */
  modifier onlyPoolAdmin() {
    IACLManager aclManager = IACLManager(ADDRESSES_PROVIDER.getACLManager());
    require(aclManager.isPoolAdmin(msg.sender), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  /**
   * @dev Only risk or pool admin can call functions marked by this modifier.
   */
  modifier onlyRiskOrPoolAdmins() {
    IACLManager aclManager = IACLManager(ADDRESSES_PROVIDER.getACLManager());
    require(
      aclManager.isRiskAdmin(msg.sender) || aclManager.isPoolAdmin(msg.sender),
      Errors.CALLER_NOT_RISK_OR_POOL_ADMIN
    );
    _;
  }

  IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;

  ISequencerOracle internal _sequencerOracle;

  uint256 internal _gracePeriod;

  /**
   * @dev Constructor
   * @param provider The address of the PoolAddressesProvider
   * @param oracle The address of the SequencerOracle
   * @param gracePeriod The duration of the grace period in seconds
   */
  constructor(IPoolAddressesProvider provider, ISequencerOracle oracle, uint256 gracePeriod) {
    ADDRESSES_PROVIDER = provider;
    _sequencerOracle = oracle;
    _gracePeriod = gracePeriod;
  }

  /// @inheritdoc IPriceOracleSentinel
  function isBorrowAllowed() public view override returns (bool) {
    return _isUpAndGracePeriodPassed();
  }

  /// @inheritdoc IPriceOracleSentinel
  function isLiquidationAllowed() public view override returns (bool) {
    return _isUpAndGracePeriodPassed();
  }

  /**
   * @notice Checks the sequencer oracle is healthy: is up and grace period passed.
   * @return True if the SequencerOracle is up and the grace period passed, false otherwise
   */
  function _isUpAndGracePeriodPassed() internal view returns (bool) {
    (, int256 answer, , uint256 lastUpdateTimestamp, ) = _sequencerOracle.latestRoundData();
    return answer == 0 && block.timestamp - lastUpdateTimestamp > _gracePeriod;
  }

  /// @inheritdoc IPriceOracleSentinel
  function setSequencerOracle(address newSequencerOracle) public onlyPoolAdmin {
    _sequencerOracle = ISequencerOracle(newSequencerOracle);
    emit SequencerOracleUpdated(newSequencerOracle);
  }

  /// @inheritdoc IPriceOracleSentinel
  function setGracePeriod(uint256 newGracePeriod) public onlyRiskOrPoolAdmins {
    _gracePeriod = newGracePeriod;
    emit GracePeriodUpdated(newGracePeriod);
  }

  /// @inheritdoc IPriceOracleSentinel
  function getSequencerOracle() public view returns (address) {
    return address(_sequencerOracle);
  }

  /// @inheritdoc IPriceOracleSentinel
  function getGracePeriod() public view returns (uint256) {
    return _gracePeriod;
  }
}
