/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/SuperFluid?utm=code
  */
  
  // SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import { SafeCast } from "SuperFluid/@openzeppelin/contracts/utils/math/SafeCast.sol";

import {
    ISuperfluid, ISuperToken, IConstantFlowAgreementV1
} from "../interfaces/superfluid/ISuperfluid.sol";

import { IERC1820Registry } from "SuperFluid/@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import { IERC777Recipient } from "SuperFluid/@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";

/**
 * @title TOGA: Transparent Ongoing Auction
 * @author Superfluid
 *
 * @dev TOGA is a simple implementation of a continuous auction.
 *      It's used to designate PICs (Patrician In Charge) - a role defined per Super Token.
 *      Anybody can become the PIC for a Super Token by staking the highest bond (denominated in the token).
 *      Staking is done by simply using ERC777.send(), transferring the bond amount to be staked to this contract.
 *      Via userData parameter (abi-encoded int96), an exitRate can be defined. If omitted, a default will be chosen.
 *      The exitRate is the flowrate at which the bond is streamed back to the PIC.
 *      Any rewards accrued by this contract (in general the whole token balance) become part of the bond.
 *      When a PIC is outbid, the current bond is transferred to it with ERC777.send().
 *
 *      changes in v2:
 *      In case that send() fails (e.g. due to a reverting hook), the bond is transferred to a custodian contract.
 *      Funds accumulated there can be withdrawn from there at any time.
 *      The current PIC can increase its bond by sending more funds using ERC777.send().
 *
 *      changes in v3:
 *      Use ERC20.transfer() instead of ERC777.send() when outbid.
 *      This allows us to eliminate the custodian contract and related complexity.
 *
 */
interface ITOGAv1 {
    /**
     * @dev get the address of the current PIC for the given token.
     * @param token The token for which to get the PIC
     */
    function getCurrentPIC(ISuperToken token) external view returns(address pic);

    /**
     * @dev get info about the state - most importantly the bond amount - of the current PIC for the given token.
     * @param token The token for which to get PIC info
     * Notes:
     * The bond changes dynamically and can both grow or shrink between 2 blocks.
     * Even the PIC itself could change anytime, this being a continuous auction.
     * @return pic Address of the current PIC. Returns the ZERO address if not set
     * @return bond The current bond amount. Can shrink or grow over time, depending on exitRate and rewards accrued
     * @return exitRate The current flowrate of given tokens from the contract to the PIC
     */
    function getCurrentPICInfo(ISuperToken token) external view
        returns(address pic, uint256 bond, int96 exitRate);

    /**
     * @dev Get the exit rate set by default for the given token and bond amount
     * @param token The token for which to get info
     * @param bondAmount The bond amount for which to make the calculation
     * @return exitRate The exit rate set by default for a bid with the given bond amount for the given token
     */
    function getDefaultExitRateFor(ISuperToken token, uint256 bondAmount) external view returns(int96 exitRate);

    /**
     * @dev Get the max exit which can be set for the given token and bond amount
     * @param token The token for which to get info
     * @param bondAmount The bond amount for which to calculate the max exit rate
     * @return exitRate The max exit rate which can be set for the given bond amount and token
     *
     * This limit is enforced only at the time of setting or updating the flow from the contract to the PIC.
     */
    function getMaxExitRateFor(ISuperToken token, uint256 bondAmount) external view returns(int96 exitRate);

    /**
    * @dev allows the current PIC for the given token to change the exit rate
    * @param token The Super Token the exit rate should be changed for
    * @param newExitRate The new exit rate. The same constraints as during bidding apply.
    *
    * Notes:
    * newExitRate can't be higher than the value returned by getMaxExitRateFor() for the given token and bond.
    * newExitRate can also be 0, this triggers closing of the flow from the contract to the PIC.
    * If newExitRate is > 0 and no flow exists, a flow is created.
    */
    function changeExitRate(ISuperToken token, int96 newExitRate) external;

    /**
     * @dev Emitted on a successful bid designating a PIC
     * @param token The Super token the new PIC bid for
     * @param pic The address of the new PIC
     * @param bond The size (amount) of the bond staked by the PIC
     * @param exitRate The flowrate at which the bond and accrued rewards will be streamed to the PIC
     * The exitRate must be greater or equal zero and respect the upper bound defined by getMaxExitRateFor()
     */
    event NewPIC(ISuperToken indexed token, address pic, uint256 bond, int96 exitRate);

    /**
     * @dev Emitted if a PIC changes the exit rate
     * @param token The Super token for which the exit rate was changed
     * @param exitRate The new flowrate of the given token from the contract to the PIC
     */
    event ExitRateChanged(ISuperToken indexed token, int96 exitRate);
}

interface ITOGAv2 is ITOGAv1 {
    /**
    * @dev allows previous PICs to withdraw bonds which couldn't be sent back to them
    * @param token The token for which to withdraw funds in custody
    */
    function withdrawFundsInCustody(ISuperToken token) external;

    /**
     * @dev Emitted if a PIC increases its bond
     * @param additionalBond The additional amount added to the bond
     */
    event BondIncreased(ISuperToken indexed token, uint256 additionalBond);
}

interface ITOGAv3 is ITOGAv1 {
    /**
     * @dev Emitted if a PIC increases its bond
     * @param additionalBond The additional amount added to the bond
     */
    event BondIncreased(ISuperToken indexed token, uint256 additionalBond);
}

contract TOGA is ITOGAv3, IERC777Recipient {

    using SafeCast for uint256;
    // lightweight struct packing an address and a bool (reentrancy guard) into 1 word
    struct LockablePIC {
        address addr;
        bool lock;
    }
    mapping(ISuperToken => LockablePIC) internal _currentPICs;
    ISuperfluid internal immutable _host;
    IConstantFlowAgreementV1 internal immutable _cfa;
    uint256 public immutable minBondDuration;
    IERC1820Registry constant internal _ERC1820_REG = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    constructor(ISuperfluid host_, uint256 minBondDuration_) {
        _host = ISuperfluid(host_);
        minBondDuration = minBondDuration_;
        _cfa = IConstantFlowAgreementV1(
            address(host_.getAgreementClass(keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")))
        );
        bytes32 erc777TokensRecipientHash = keccak256("ERC777TokensRecipient");
        _ERC1820_REG.setInterfaceImplementer(address(this), erc777TokensRecipientHash, address(this));
        _ERC1820_REG.setInterfaceImplementer(address(this), keccak256("TOGAv1"), address(this));
        _ERC1820_REG.setInterfaceImplementer(address(this), keccak256("TOGAv2"), address(this));
    }

    function getCurrentPIC(ISuperToken token) external view override returns(address pic) {
        return _currentPICs[token].addr;
    }

    function getCurrentPICInfo(ISuperToken token)
        external view override
        returns(address pic, uint256 bond, int96 exitRate)
    {
        (, exitRate,,) = _cfa.getFlow(token, address(this), _currentPICs[token].addr);
        return (
            _currentPICs[token].addr,
            _getCurrentPICBond(token),
            exitRate
        );
    }

    function capToInt96(int256 value) internal pure returns(int96) {
        return value < type(int96).max ? int96(value) : type(int96).max;
    }

    function getDefaultExitRateFor(ISuperToken /*token*/, uint256 bondAmount)
        public view override
        returns(int96 exitRate)
    {
        return capToInt96((bondAmount / (minBondDuration * 4)).toInt256());
    }

    function getMaxExitRateFor(ISuperToken /*token*/, uint256 bondAmount)
        external view override
        returns(int96 exitRate)
    {
        return capToInt96((bondAmount / minBondDuration).toInt256());
    }

    function changeExitRate(ISuperToken token, int96 newExitRate) external override {
        address currentPICAddr = _currentPICs[token].addr;
        require(msg.sender == currentPICAddr, "TOGA: only PIC allowed");
        require(newExitRate >= 0, "TOGA: negative exitRate not allowed");
        require(uint256(int256(newExitRate)) * minBondDuration <= _getCurrentPICBond(token), "TOGA: exitRate too high");

        (, int96 curExitRate,,) = _cfa.getFlow(token, address(this), currentPICAddr);
        if (curExitRate > 0 && newExitRate > 0) {
            // need to update existing flow
            _host.callAgreement(
                _cfa,
                abi.encodeCall(
                    _cfa.updateFlow,
                    (
                        token,
                        currentPICAddr,
                        newExitRate,
                        new bytes(0)
                    )
                ),
                "0x"
            );
        } else if (curExitRate == 0 && newExitRate > 0) {
            // no pre-existing flow, need to create
            _host.callAgreement(
                _cfa,
                abi.encodeCall(
                    _cfa.createFlow,
                    (
                        token,
                        currentPICAddr,
                        newExitRate,
                        new bytes(0)
                    )
                ),
                "0x"
            );
        } else if (curExitRate > 0 && newExitRate == 0) {
            // need to close existing flow
            _host.callAgreement(
                _cfa,
                abi.encodeCall(
                    _cfa.deleteFlow,
                    (
                        token,
                        address(this),
                        currentPICAddr,
                        new bytes(0)
                    )
                ),
                "0x"
            );
        } // else do nothing (no existing flow, newExitRate == 0)

        emit ExitRateChanged(token, newExitRate);
    }

    // ============ internal ============

    function _getCurrentPICBond(ISuperToken token) internal view returns(uint256 bond) {
        (int256 availBal, uint256 deposit, , ) = token.realtimeBalanceOfNow(address(this));
        // The protocol guarantees that we get no values leading to an overflow here
        return availBal + int256(deposit) > 0 ? uint256(availBal + int256(deposit)) : 0;
    }

    // This is the logic for designating a PIC via successful bid - invoked only by the ERC777 send() hook
    // Relies on CFA (SuperApp) hooks not being able to block the transaction by reverting.
    function _becomePIC(ISuperToken token, address newPIC, uint256 amount, int96 exitRate) internal {
        require(!_currentPICs[token].lock, "TOGA: reentrancy not allowed");
        require(exitRate >= 0, "TOGA: negative exitRate not allowed");
        require(uint256(int256(exitRate)) * minBondDuration <= amount, "TOGA: exitRate too high");
        // cannot underflow because amount was added to the balance before
        uint256 currentPICBond = _getCurrentPICBond(token) - amount;
        require(amount > currentPICBond, "TOGA: bid too low");
        address currentPICAddr = _currentPICs[token].addr;

        _currentPICs[token].lock = true; // set reentrancy guard

        // close flow to current (soon previous) PIC if exists
        (, int96 curFlowRate,,) = _cfa.getFlow(token, address(this), currentPICAddr);
        if (curFlowRate > 0) {
            _host.callAgreement(
                _cfa,
                abi.encodeCall(
                    _cfa.deleteFlow,
                    (
                        token,
                        address(this),
                        currentPICAddr,
                        new bytes(0)
                    )
                ),
                "0x"
            );
        }

        // if no PIC was set yet, rewards already accumulated become part of the bond of the first PIC
        if (currentPICAddr != address(0)) {
            // transfer remaining bond to current PIC
            token.transfer(currentPICAddr, currentPICBond);
        }

        // set new PIC
        // solhint-disable-next-line reentrancy
        _currentPICs[token].addr = newPIC;

        // if exitRate > 0, open stream to new PIC
        if (exitRate > 0) {
            _host.callAgreement(
                _cfa,
                abi.encodeCall(
                    _cfa.createFlow,
                    (
                        token,
                        newPIC,
                        exitRate,
                        new bytes(0)
                    )
                ),
                "0x"
            );
        }

        // solhint-disable-next-line reentrancy
        _currentPICs[token].lock = false; // release reentrancy guard
        emit NewPIC(token, newPIC, amount, exitRate);
    }

    // ============ IERC777Recipient ============

    function tokensReceived(
        address /*operator*/,
        address from,
        address /*to*/,
        uint256 amount,
        bytes calldata userData,
        bytes calldata /*operatorData*/
    ) override external {
        // if it's not a SuperToken, something will revert along the way
        ISuperToken token = ISuperToken(msg.sender);

        if(from != _currentPICs[token].addr) {
            int96 exitRate = userData.length == 0 ?
                getDefaultExitRateFor(token, amount) :
                abi.decode(userData, (int96));
            _becomePIC(token, from, amount, exitRate);
        } else {
            // current PIC increases the bond
            emit BondIncreased(token, amount);
        }
    }
}
