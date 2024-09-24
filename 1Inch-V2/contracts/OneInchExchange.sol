/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/1Inch-V2?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "1Inch-V2/@openzeppelin/contracts/access/Ownable.sol";
import "1Inch-V2/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "1Inch-V2/@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IChi.sol";
import "./interfaces/IERC20Permit.sol";
import "./interfaces/IOneInchCaller.sol";
import "./helpers/RevertReasonParser.sol";
import "./helpers/UniERC20.sol";

contract OneInchExchange is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using UniERC20 for IERC20;

    uint256 private constant _PARTIAL_FILL = 0x01;
    uint256 private constant _REQUIRES_EXTRA_ETH = 0x02;
    uint256 private constant _SHOULD_CLAIM = 0x04;
    uint256 private constant _BURN_FROM_MSG_SENDER = 0x08;
    uint256 private constant _BURN_FROM_TX_ORIGIN = 0x10;

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 guaranteedAmount;
        uint256 flags;
        address referrer;
        bytes permit;
    }

    event Swapped(
        address indexed sender,
        IERC20 indexed srcToken,
        IERC20 indexed dstToken,
        address dstReceiver,
        uint256 amount,
        uint256 spentAmount,
        uint256 returnAmount,
        uint256 minReturnAmount,
        uint256 guaranteedAmount,
        address referrer
    );

    event Error(string reason);

    function discountedSwap(
        IOneInchCaller caller,
        SwapDescription calldata desc,
        IOneInchCaller.CallDescription[] calldata calls
    ) external payable returns (uint256 returnAmount) {
        uint256 initialGas = gasleft();

        address chiSource = address(0);
        if (desc.flags & _BURN_FROM_MSG_SENDER != 0) {
            chiSource = msg.sender;
        } else if (desc.flags & _BURN_FROM_TX_ORIGIN != 0) {
            chiSource = tx.origin; // solhint-disable-line avoid-tx-origin
        } else {
            revert("Incorrect CHI burn flags");
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(this).delegatecall(
            abi.encodeWithSelector(this.swap.selector, caller, desc, calls)
        );
        if (success) {
            returnAmount = abi.decode(data, (uint256));
        } else {
            if (msg.value > 0) {
                msg.sender.transfer(msg.value);
            }
            emit Error(RevertReasonParser.parse(data, "Swap failed: "));
        }

        (IChi chi, uint256 amount) = caller.calculateGas(
            initialGas.sub(gasleft()),
            desc.flags,
            msg.data.length
        );
        chi.freeFromUpTo(chiSource, amount);
    }

    function swap(
        IOneInchCaller caller,
        SwapDescription calldata desc,
        IOneInchCaller.CallDescription[] calldata calls
    ) external payable whenNotPaused returns (uint256 returnAmount) {
        require(desc.minReturnAmount > 0, "Min return should not be 0");
        require(calls.length > 0, "Call data should exist");

        uint256 flags = desc.flags;
        IERC20 srcToken = desc.srcToken;
        IERC20 dstToken = desc.dstToken;

        if (flags & _REQUIRES_EXTRA_ETH != 0) {
            require(
                msg.value > (srcToken.isETH() ? desc.amount : 0),
                "Invalid msg.value"
            );
        } else {
            require(
                msg.value == (srcToken.isETH() ? desc.amount : 0),
                "Invalid msg.value"
            );
        }

        if (flags & _SHOULD_CLAIM != 0) {
            require(!srcToken.isETH(), "Claim token is ETH");
            _claim(srcToken, desc.srcReceiver, desc.amount, desc.permit);
        }

        address dstReceiver = (desc.dstReceiver == address(0))
            ? msg.sender
            : desc.dstReceiver;
        uint256 initialSrcBalance = (flags & _PARTIAL_FILL != 0)
            ? srcToken.uniBalanceOf(msg.sender)
            : 0;
        uint256 initialDstBalance = dstToken.uniBalanceOf(dstReceiver);

        caller.makeCalls{value: msg.value}(calls);

        uint256 spentAmount = desc.amount;
        returnAmount = dstToken.uniBalanceOf(dstReceiver).sub(
            initialDstBalance
        );

        if (flags & _PARTIAL_FILL != 0) {
            spentAmount = initialSrcBalance.add(desc.amount).sub(
                srcToken.uniBalanceOf(msg.sender)
            );
            require(
                returnAmount.mul(desc.amount) >=
                    desc.minReturnAmount.mul(spentAmount),
                "Return amount is not enough"
            );
        } else {
            require(
                returnAmount >= desc.minReturnAmount,
                "Return amount is not enough"
            );
        }

        _emitSwapped(
            desc,
            srcToken,
            dstToken,
            dstReceiver,
            spentAmount,
            returnAmount
        );
    }

    function _emitSwapped(
        SwapDescription calldata desc,
        IERC20 srcToken,
        IERC20 dstToken,
        address dstReceiver,
        uint256 spentAmount,
        uint256 returnAmount
    ) private {
        emit Swapped(
            msg.sender,
            srcToken,
            dstToken,
            dstReceiver,
            desc.amount,
            spentAmount,
            returnAmount,
            desc.minReturnAmount,
            desc.guaranteedAmount,
            desc.referrer
        );
    }

    function _claim(
        IERC20 token,
        address dst,
        uint256 amount,
        bytes calldata permit
    ) private {
        // TODO: Is it safe to call permit on tokens without implemented permit? Fallback will be called. Is it bad for proxies?

        if (permit.length == 32 * 7) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = address(token).call(
                abi.encodeWithSelector(IERC20Permit.permit.selector, permit)
            );
            if (!success) {
                revert(
                    RevertReasonParser.parse(result, "Permit call failed: ")
                );
            }
        }

        token.safeTransferFrom(msg.sender, dst, amount);
    }

    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.uniTransfer(msg.sender, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }
}
