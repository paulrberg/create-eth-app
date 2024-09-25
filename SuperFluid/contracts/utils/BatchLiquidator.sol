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
    ISuperfluid, ISuperAgreement, ISuperToken, IConstantFlowAgreementV1
} from "../interfaces/superfluid/ISuperfluid.sol";
import { ERC20 } from "SuperFluid/@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Batch liquidator contract
 * @author Superfluid
 * @dev This contract allows to delete multiple flows in a single transaction.
 * @notice Reduces calldata by having host and cfa hardcoded, this can make a significant difference in tx fees on L2s
 */

contract BatchLiquidator {

    error ARRAY_SIZES_DIFFERENT();

    address public immutable host;
    address public immutable cfa;

    constructor(address host_, address cfa_) {
        host = host_;
        cfa = cfa_;
    }

    /**
     * @dev Delete flows in batch
     * @param superToken - The super token the flows belong to.
     * @param senders - List of senders.
     * @param receivers - Corresponding list of receivers.
     * @return nSuccess - Number of succeeded deletions.
     */
    function deleteFlows(
        address superToken,
        address[] calldata senders, address[] calldata receivers
    ) external returns (uint nSuccess) {
        uint256 length = senders.length;
        if(length != receivers.length) revert ARRAY_SIZES_DIFFERENT();
        for (uint256 i; i < length;) {
            // We tolerate any errors occured during liquidations.
            // It could be due to flow had been liquidated by others.
            // solhint-disable-next-line avoid-low-level-calls
            (bool success,) = address(host).call(
                abi.encodeCall(
                    ISuperfluid(host).callAgreement,
                    (
                        ISuperAgreement(cfa),
                        abi.encodeCall(
                            IConstantFlowAgreementV1(cfa).deleteFlow,
                            (
                                ISuperToken(superToken),
                                senders[i],
                                receivers[i],
                                new bytes(0)
                            )
                        ),
                        new bytes(0)
                    )
                )
            );
            if (success) ++nSuccess;
            unchecked { i++; }
        }

        // If the liquidation(s) resulted in any super token
        // rewards, send them all to the sender instead of having them
        // locked in the contract
        {
            uint256 balance = ERC20(superToken).balanceOf(address(this));
            if (balance > 0) {
                // don't fail for non-transferrable tokens
                try ERC20(superToken).transferFrom(address(this), msg.sender, balance)
                // solhint-disable-next-line no-empty-blocks
                {} catch {}
            }
        }
    }

    // single flow delete with check for success
    function deleteFlow(address superToken, address sender, address receiver) external {
        /* solhint-disable */
        (bool success, bytes memory returndata) = address(host).call(
            abi.encodeCall(
                ISuperfluid(host).callAgreement,
                (
                    ISuperAgreement(cfa),
                    abi.encodeCall(
                        IConstantFlowAgreementV1(cfa).deleteFlow,
                        (
                            ISuperToken(superToken),
                            sender,
                            receiver,
                            new bytes(0)
                        )
                    ),
                    new bytes(0)
                )
            )
        );
        if (!success) {
            if (returndata.length == 0) revert();
            // solhint-disable
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
        }
        /* solhint-enable */
        // If the liquidation(s) resulted in any super token
        // rewards, send them all to the sender instead of having them
        // locked in the contract
        {
            uint256 balance = ERC20(superToken).balanceOf(address(this));
            if (balance > 0) {
                try ERC20(superToken).transferFrom(address(this), msg.sender, balance)
                // solhint-disable-next-line no-empty-blocks
                {} catch {}
            }
        }
    }
}
