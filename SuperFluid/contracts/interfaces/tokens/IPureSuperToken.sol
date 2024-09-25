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
  
  // SPDX-License-Identifier: MIT
pragma solidity >= 0.8.11;

import { ISuperToken } from "../superfluid/ISuperToken.sol";

/**
 * @title Pure Super Token custom interface
 * @author Superfluid
 */
interface IPureSuperTokenCustom {
    function initialize(string calldata name, string calldata symbol, uint256 initialSupply) external;
}

/**
 * @title Pure Super Token interface
 * @author Superfluid
 */
// solhint-disable-next-line no-empty-blocks
interface IPureSuperToken is IPureSuperTokenCustom, ISuperToken {}
