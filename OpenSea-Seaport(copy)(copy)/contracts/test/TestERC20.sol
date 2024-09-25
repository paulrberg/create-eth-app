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
  
  // SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { ERC20 } from "OpenSea-Seaport/@rari-capital/solmate/src/tokens/ERC20.sol";

// Used for minting test ERC20s in our tests
contract TestERC20 is ERC20("Test20", "TST20", 18) {
    bool public blocked;

    bool public noReturnData;

    constructor() {
        blocked = false;
        noReturnData = false;
    }

    function blockTransfer(bool blocking) external {
        blocked = blocking;
    }

    function setNoReturnData(bool noReturn) external {
        noReturnData = noReturn;
    }

    function mint(address to, uint256 amount) external returns (bool) {
        _mint(to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool ok) {
        if (blocked) {
            return false;
        }

        uint256 allowed = allowance[from][msg.sender];

        if (amount > allowed) {
            revert("NOT_AUTHORIZED");
        }

        super.transferFrom(from, to, amount);

        if (noReturnData) {
            assembly {
                return(0, 0)
            }
        }

        ok = true;
    }

    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool) {
        uint256 current = allowance[msg.sender][spender];
        uint256 remaining = type(uint256).max - current;
        if (amount > remaining) {
            amount = remaining;
        }
        approve(spender, current + amount);
        return true;
    }
}
