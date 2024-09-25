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

import { BatchOperation, ISuperfluid } from "../interfaces/superfluid/ISuperfluid.sol";
import { CallUtils } from "../libs/CallUtils.sol";

abstract contract ForwarderBase {
    ISuperfluid internal immutable _host;

    constructor(ISuperfluid host) {
        _host = host;
    }

    // compiles the calldata of a single operation for the host invocation and executes it
    function _forwardBatchCall(address target, bytes memory callData, bytes memory userData) internal returns (bool) {
        ISuperfluid.Operation[] memory ops = new ISuperfluid.Operation[](1);
        ops[0] = ISuperfluid.Operation(
            BatchOperation.OPERATION_TYPE_SUPERFLUID_CALL_AGREEMENT, // type
            address(target), // target
            abi.encode( // data
            callData, userData)
        );

        bytes memory fwBatchCallData = abi.encodeCall(_host.forwardBatchCall, (ops));

        // https://eips.ethereum.org/EIPS/eip-2771
        // we encode the msg.sender as the last 20 bytes per EIP-2771 to extract the original txn signer later on
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnedData) = address(_host).call(abi.encodePacked(fwBatchCallData, msg.sender));

        if (!success) {
            CallUtils.revertFromReturnedData(returnedData);
        }

        return true;
    }
}
