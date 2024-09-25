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

import { IRelayRecipient } from "../interfaces/utils/IRelayRecipient.sol";


/**
 * @title Base relay recipient contract
 * @author Superfluid
 * @dev A base contract to be inherited by any contract that want to receive relayed transactions
 *      A subclass must use "_msgSender()" instead of "msg.sender"
 *      MODIFIED FROM: https://github.com/opengsn/forwarder/blob/master/contracts/BaseRelayRecipient.sol
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /**
     * @dev Check if the forwarder is trusted
     */
    function isTrustedForwarder(address forwarder) public view virtual override returns(bool);

    /**
     * @dev Return the transaction signer of this call
     *
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _getTransactionSigner() internal virtual view returns (address payable ret) {
        require(msg.data.length >= 24 && isTrustedForwarder(msg.sender), "Not trusted forwarder");
        // At this point we know that the sender is a trusted forwarder,
        // so we trust that the last bytes of msg.data are the verified sender address.
        // extract sender address from the end of msg.data
        assembly {
            ret := shr(96,calldataload(sub(calldatasize(),20)))
        }
    }

}
