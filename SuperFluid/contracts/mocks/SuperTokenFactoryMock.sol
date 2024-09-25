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

import { 
    ISuperfluid,
    ISuperToken,
    SuperTokenFactoryBase,
    IConstantInflowNFT,
    IConstantOutflowNFT
} from "../superfluid/SuperTokenFactory.sol";

contract SuperTokenFactoryStorageLayoutTester is SuperTokenFactoryBase {
    constructor(
        ISuperfluid host,
        ISuperToken superTokenLogic,
        IConstantOutflowNFT constantOutflowNFT,
        IConstantInflowNFT constantInflowNFT
    )
        SuperTokenFactoryBase(
            host,
            superTokenLogic,
            constantOutflowNFT,
            constantInflowNFT
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }

    // @dev Make sure the storage layout never change over the course of the development
    function validateStorageLayout() external pure {
        uint256 slot;
        uint256 offset;

        // Initializable bool _initialized and bool _initialized

        assembly { slot:= _superTokenLogicDeprecated.slot offset := _superTokenLogicDeprecated.offset }
        require (slot == 0 && offset == 2, "_superTokenLogicDeprecated changed location");

        assembly { slot := _canonicalWrapperSuperTokens.slot offset := _canonicalWrapperSuperTokens.offset }
        require(slot == 1 && offset == 0, "_canonicalWrapperSuperTokens changed location");
    }
}

contract SuperTokenFactoryUpdateLogicContractsTester is SuperTokenFactoryBase {
    uint256 public newVariable;

    constructor(
        ISuperfluid host,
        ISuperToken superTokenLogic,
        IConstantOutflowNFT constantOutflowNFT,
        IConstantInflowNFT constantInflowNFT
    )
        SuperTokenFactoryBase(
            host,
            superTokenLogic,
            constantOutflowNFT,
            constantInflowNFT
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }
}

contract SuperTokenFactoryMock is SuperTokenFactoryBase {
    constructor(
        ISuperfluid host,
        ISuperToken superTokenLogic,
        IConstantOutflowNFT constantOutflowNFT,
        IConstantInflowNFT constantInflowNFT
    )
        SuperTokenFactoryBase(
            host,
            superTokenLogic,
            constantOutflowNFT,
            constantInflowNFT
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }
}

contract SuperTokenFactoryMock42 is SuperTokenFactoryBase {
    constructor(
        ISuperfluid host,
        ISuperToken superTokenLogic,
        IConstantOutflowNFT constantOutflowNFT,
        IConstantInflowNFT constantInflowNFT
    )
        SuperTokenFactoryBase(
            host,
            superTokenLogic,
            constantOutflowNFT,
            constantInflowNFT
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }
}
