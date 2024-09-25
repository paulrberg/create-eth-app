/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Synthetix?utm=code
  */
  
  pragma solidity ^0.5.16;

import "../BaseMigration.sol";
import "../PerpsV2ExchangeRate.sol";

interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_CaphOptimismStep14 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](1);
        contracts[0] = address(perpsv2exchangerate_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        perpsv2exchangerate_removeAssociatedContracts_0();

        // NOMINATE OWNERSHIP back to owner for aforementioned contracts
        nominateAll();
    }

    function acceptAll() internal {
        address[] memory contracts = contractsRequiringOwnership();
        for (uint i = 0; i < contracts.length; i++) {
            Owned(contracts[i]).acceptOwnership();
        }
    }

    function nominateAll() internal {
        address[] memory contracts = contractsRequiringOwnership();
        for (uint i = 0; i < contracts.length; i++) {
            returnOwnership(contracts[i]);
        }
    }

    function perpsv2exchangerate_removeAssociatedContracts_0() internal {
        address[] memory perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0 = new address[](48);
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[0] = address(
            0x0454E103a712b257819efBBB797EaE80918dd2FF
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[1] = address(
            0x08941749026fF010c22E8B9d93a76EEBFC61C13b
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[2] = address(
            0x0BB25623946960D8FB1696a9D70466766F2C8aa7
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[3] = address(
            0x0f5af2A8a4Df79e354455788fdA73bed85AB435C
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[4] = address(
            0x139AF9de51Ca2594911502E7A5653D4693EFb4ED
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[5] = address(
            0x14688DFAa8b4085DA485579f72F3DE467485411a
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[6] = address(
            0x1651e832dcc1B9cF697810d822aee35A9f5fFD64
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[7] = address(
            0x194ffc3D2cE0552720F24FefDf57a6c534223174
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[8] = address(
            0x2A656E9618185782A638c86C64b5702854DDB11A
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[9] = address(
            0x2BF61b08F3e8DA40799D90C3b1e60f1c4DDb7fDA
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[10] = address(
            0x31A53d5238391d1449b443eDB5476b5D8dF23239
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[11] = address(
            0x3459276E8f644F111539804e08253799b176Ab83
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[12] = address(
            0x3c30CBd400f8e7c099ab27cF28DA843cD4433FFE
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[13] = address(
            0x43406c99fc8a7776F2870800e38FF5c8Cc96a2fE
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[14] = address(
            0x45C93D2C1994a70fD2Af98DA6ba100953b96A768
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[15] = address(
            0x580f76aF1FC4BB29F0032EeC6e0F7460D26b5f56
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[16] = address(
            0x5AE6b5DD28F44689e4D17F47aeF1f863C36Df556
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[17] = address(
            0x5d89892BCa7aa5619fd6168D38F73bb84D777e9C
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[18] = address(
            0x62B6f3733AB95Ec88864F03f758DE4377d6C751d
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[19] = address(
            0x6B9cbCdaE03C4cDfD9fb9D987C74856Ac332fDCf
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[20] = address(
            0x70aEA7B455510640217CBCB78C5f2d29DB5a4a01
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[21] = address(
            0x7F87AEc4938770e52AF9A0B5239521BD9C53F28E
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[22] = address(
            0x85875A05bE4db7a21dB6C53CeD09b06a5aD83402
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[23] = address(
            0x8c2c26494eAe20A8a22f94ED5Fa4B104FAD6bcca
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[24] = address(
            0x909c690556D8389AEa348377EB27dECFb1b27d29
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[25] = address(
            0x95597eaC456983645d4aD0cC83C5356cc245Ea0D
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[26] = address(
            0x9B20476899C8Fb22d96af37D2017016A80647159
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[27] = address(
            0xAEb1Cc5FD71CfFD1462808eE13b1051196bF6224
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[28] = address(
            0xB0A058c7781F6EcA709d4b469FCc522a6fA38E60
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[29] = address(
            0xB9202087852298E5e2ebC0c30758fA4E07faf6fB
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[30] = address(
            0xBF3B13F155070a61156f261b26D0Eb06f629C2e6
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[31] = address(
            0xC0204F82ce1e25d15D2cE8DC1deA3f319BB64a8F
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[32] = address(
            0xD8c3F087000DC990Fc84a776aED78d31507F716B
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[33] = address(
            0xDF89210B03E319B08EC0cC73C4B50468306e1252
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[34] = address(
            0xE99dB61288A4e8968ee58C03cc142c6ddB500598
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[35] = address(
            0xF40482B4DA5509d6a9fb3Bed08E2356D72c31028
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[36] = address(
            0xF612F3098a277cb80Ad03f20cf7787aD1Dc48f4a
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[37] = address(
            0xF6CB6699367F8f61A8bF504CBe914C639D051E19
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[38] = address(
            0xF7df260a4F46Eaf5A82589B9e9D3879e6FCee431
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[39] = address(
            0xaf476d7817105437aed79a86E802b79D4B1c473F
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[40] = address(
            0xcC0ceC53572d4e10a8fdABb468356287B170c6A9
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[41] = address(
            0xd2471115Be883EA7A32907D78062C323a5E85593
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[42] = address(
            0xe343542366A9f3Af56Acc6D68154Cfaf23efeba6
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[43] = address(
            0xf3DCf19D397F5A696A106b4287379Fb53fE33005
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[44] = address(
            0xf67fDa142f31686523D2b52CE25aD66895f23116
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[45] = address(
            0xf8B9Dd242BDAF6242cb783F02b49D1Dd9126DE5c
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[46] = address(
            0xfce521766201013974Dbf3B71E68b0CF8FBcd05B
        );
        perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0[47] = address(
            0xfde9d8F4d2fB18823363fdd0E1fF305c4696A19D
        );
        perpsv2exchangerate_i.removeAssociatedContracts(
            perpsv2exchangerate_removeAssociatedContracts_associatedContracts_0_0
        );
    }
}
