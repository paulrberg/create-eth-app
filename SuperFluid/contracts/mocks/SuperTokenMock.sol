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

import { ISuperfluid, IConstantInflowNFT, IConstantOutflowNFT } from "../interfaces/superfluid/ISuperfluid.sol";
import { SuperToken } from "../superfluid/SuperToken.sol";

contract SuperTokenStorageLayoutTester is SuperToken {

    constructor(
        ISuperfluid host,
        IConstantOutflowNFT constantOutflowNFTProxy,
        IConstantInflowNFT constantInflowNFTProxy
    )
        SuperToken(host, constantOutflowNFTProxy, constantInflowNFTProxy) // solhint-disable-next-line no-empty-blocks
    {}

    // @dev Make sure the storage layout never change over the course of the development
    function validateStorageLayout() external pure {
        uint256 slot;
        uint256 offset;

        // Initializable _initialized and _initialized

        // SuperfluidToken storages

        assembly { slot:= _inactiveAgreementBitmap.slot offset := _inactiveAgreementBitmap.offset }
        require (slot == 1 && offset == 0, "_inactiveAgreementBitmap changed location");

        assembly { slot:= _sharedSettledBalances.slot offset := _sharedSettledBalances.offset }
        require (slot == 2 && offset == 0, "_sharedSettledBalances changed location");

        assembly { slot:= _totalSupply.slot offset := _totalSupply.offset }
        require (slot == 3 && offset == 0, "_totalSupply changed location");

        assembly { slot:= _reserve4.slot offset := _reserve4.offset }
        require (slot == 4 && offset == 0, "_reserve4 changed location");

        assembly { slot:= _reserve13.slot offset := _reserve13.offset }
        require (slot == 13 && offset == 0, "_reserve9 changed location");

        // SuperToken storages

        assembly { slot:= _underlyingToken.slot offset := _underlyingToken.offset }
        require (slot == 14 && offset == 0, "_underlyingToken changed location");

        assembly { slot:= _underlyingDecimals.slot offset := _underlyingDecimals.offset }
        require (slot == 14 && offset == 20, "_underlyingDecimals changed location");

        assembly { slot:= _name.slot offset := _name.offset }
        require (slot == 15 && offset == 0, "_name changed location");

        assembly { slot:= _symbol.slot offset := _symbol.offset }
        require (slot == 16 && offset == 0, "_symbol changed location");

        assembly { slot:= _allowances.slot offset := _allowances.offset }
        require (slot == 17 && offset == 0, "_allowances changed location");

        assembly { slot:= _operators.slot offset := _operators.offset }
        require (slot == 18 && offset == 0, "_operators changed location");
        // uses 4 slots

        assembly { slot:= _reserve22.slot offset := _reserve22.offset }
        require (slot == 22 && offset == 0, "_reserve22 changed location");

        assembly { slot:= _reserve31.slot offset := _reserve31.offset }
        require (slot == 31 && offset == 0, "_reserve31 changed location");
    }

    function getLastSuperTokenStorageSlot() external pure returns (uint slot) {
        assembly { slot:= _reserve31.slot }
    }
}

contract SuperTokenMock is SuperToken {

    uint256 immutable public waterMark;

    constructor(
        ISuperfluid host,
        uint256 w,
        IConstantOutflowNFT constantOutflowNFTProxy,
        IConstantInflowNFT constantInflowNFTProxy
    ) SuperToken(host, constantOutflowNFTProxy, constantInflowNFTProxy) {
        waterMark = w;
    }

    /**
     * ERC-20 mockings
     */
    function approveInternal(address owner, address spender, uint256 value) external {
        _approve(owner, spender, value);
    }

    function transferInternal(address from, address to, uint256 value) external {
        _transferFrom(from, from, to, value);
    }

    /**
     * ERC-777 mockings
     */
    function setupDefaultOperators(address[] memory operators) external {
        _setupDefaultOperators(operators);
    }

    function mintInternal(
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) external {
        _mint(msg.sender, to, amount, true /* invokeHook */, true /* requireReceptionAck */, userData, operatorData);
    }
}
