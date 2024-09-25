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
pragma solidity >=0.8.11;

import { ISuperfluidToken } from "./ISuperfluidToken.sol";
import { IFlowNFTBase } from "./IFlowNFTBase.sol";

interface IConstantOutflowNFT is IFlowNFTBase {
    /**************************************************************************
     * Custom Errors
     *************************************************************************/

    error COF_NFT_INVALID_SUPER_TOKEN();            // 0x6de98774
    error COF_NFT_MINT_TO_AND_FLOW_RECEIVER_SAME(); // 0x0d1d1161
    error COF_NFT_MINT_TO_ZERO_ADDRESS();           // 0x43d05e51
    error COF_NFT_ONLY_CONSTANT_INFLOW();           // 0xa495a718
    error COF_NFT_ONLY_FLOW_AGREEMENTS();           // 0xd367b64f
    error COF_NFT_TOKEN_ALREADY_EXISTS();           // 0xe2480183


    /**************************************************************************
     * Write Functions
     *************************************************************************/

    /// @notice The onCreate function is called when a new flow is created.
    /// @param token the super token passed from the CFA (flowVars)
    /// @param flowSender the flow sender
    /// @param flowReceiver the flow receiver
    function onCreate(ISuperfluidToken token, address flowSender, address flowReceiver) external;

    /// @notice The onUpdate function is called when a flow is updated.
    /// @param token the super token passed from the CFA (flowVars)
    /// @param flowSender the flow sender
    /// @param flowReceiver the flow receiver
    function onUpdate(ISuperfluidToken token, address flowSender, address flowReceiver) external;

    /// @notice The onDelete function is called when a flow is deleted.
    /// @param token the super token passed from the CFA (flowVars)
    /// @param flowSender the flow sender
    /// @param flowReceiver the flow receiver
    function onDelete(ISuperfluidToken token, address flowSender, address flowReceiver) external;
}
