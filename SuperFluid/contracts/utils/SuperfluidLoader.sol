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

import { IResolver } from "../interfaces/utils/IResolver.sol";
import {
    ISuperfluid,
    ISuperTokenFactory,
    ISuperAgreement
} from "../interfaces/superfluid/ISuperfluid.sol";

/**
 * @title Superfluid loader contract
 * @author Superfluid
 * @dev A on-chain utility contract for loading framework objects in one view function.
 *
 * NOTE:
 * Q: Why don't we just use https://www.npmjs.com/package/ethereum-multicall?
 * A: Well, no strong reason other than also allowing on-chain one view function loading.
 */
contract SuperfluidLoader {

    IResolver private immutable _resolver;

    struct Framework {
        ISuperfluid superfluid;
        ISuperTokenFactory superTokenFactory;
        ISuperAgreement agreementCFAv1;
        ISuperAgreement agreementIDAv1;
    }

    constructor(IResolver resolver) {
        _resolver = resolver;
    }

    /**
     * @dev Load framework objects
     * @param releaseVersion Protocol release version of the deployment
     */
    function loadFramework(string calldata releaseVersion)
        external view
        returns (Framework memory result)
    {
        // load superfluid host contract
        result.superfluid = ISuperfluid(_resolver.get(
            string.concat("Superfluid.", releaseVersion)
        ));
        result.superTokenFactory = result.superfluid.getSuperTokenFactory();
        result.agreementCFAv1 = result.superfluid.getAgreementClass(
            keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")
        );
        result.agreementIDAv1 = result.superfluid.getAgreementClass(
            keccak256("org.superfluid-finance.agreements.InstantDistributionAgreement.v1")
        );
    }
}
