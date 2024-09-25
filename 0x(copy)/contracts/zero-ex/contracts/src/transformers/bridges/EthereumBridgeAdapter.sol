/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/0x?utm=code
  */
  
  // SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./AbstractBridgeAdapter.sol";
import "./BridgeProtocols.sol";
import "./mixins/MixinAaveV2.sol";
import "./mixins/MixinBalancer.sol";
import "./mixins/MixinBalancerV2Batch.sol";
import "./mixins/MixinBancorV3.sol";
import "./mixins/MixinBarter.sol";
import "./mixins/MixinCompound.sol";
import "./mixins/MixinCurve.sol";
import "./mixins/MixinCurveV2.sol";
import "./mixins/MixinCryptoCom.sol";
import "./mixins/MixinDodo.sol";
import "./mixins/MixinDodoV2.sol";
import "./mixins/MixinKyberDmm.sol";
import "./mixins/MixinKyberElastic.sol";
import "./mixins/MixinLido.sol";
import "./mixins/MixinMakerPSM.sol";
import "./mixins/MixinMaverickV1.sol";
import "./mixins/MixinNerve.sol";
import "./mixins/MixinSynthetix.sol";
import "./mixins/MixinUniswap.sol";
import "./mixins/MixinUniswapV2.sol";
import "./mixins/MixinUniswapV3.sol";
import "./mixins/MixinZeroExBridge.sol";

contract EthereumBridgeAdapter is
    AbstractBridgeAdapter(1, "Ethereum"),
    MixinAaveV2,
    MixinBalancer,
    MixinBalancerV2Batch,
    MixinBancorV3,
    MixinBarter,
    MixinCompound,
    MixinCurve,
    MixinCurveV2,
    MixinCryptoCom,
    MixinDodo,
    MixinDodoV2,
    MixinKyberDmm,
    MixinKyberElastic,
    MixinLido,
    MixinMakerPSM,
    MixinMaverickV1,
    MixinNerve,
    MixinSynthetix,
    MixinUniswap,
    MixinUniswapV2,
    MixinUniswapV3,
    MixinZeroExBridge
{
    constructor(
        IEtherToken weth
    ) public MixinBancorV3(weth) MixinCompound(weth) MixinCurve(weth) MixinLido(weth) MixinUniswap(weth) {}

    function _trade(
        BridgeOrder memory order,
        IERC20Token sellToken,
        IERC20Token buyToken,
        uint256 sellAmount,
        bool dryRun
    ) internal override returns (uint256 boughtAmount, bool supportedSource) {
        uint128 protocolId = uint128(uint256(order.source) >> 128);
        if (protocolId == BridgeProtocols.CURVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurve(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.CURVEV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurveV2(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV3) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV3(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV2(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAP) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswap(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.BALANCER) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBalancer(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.BALANCERV2BATCH) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBalancerV2Batch(sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.MAKERPSM) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeMakerPsm(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.DODO) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeDodo(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.DODOV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeDodoV2(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.CRYPTOCOM) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCryptoCom(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.NERVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeNerve(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.KYBERDMM) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeKyberDmm(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.KYBERELASTIC) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeKyberElastic(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.LIDO) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeLido(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.AAVEV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeAaveV2(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.COMPOUND) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCompound(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.BANCORV3) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBancorV3(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.SYNTHETIX) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeSynthetix(sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.BARTER) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBarter(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.MAVERICKV1) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeMaverickV1(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNKNOWN) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeZeroExBridge(sellToken, buyToken, sellAmount, order.bridgeData);
        }

        emit BridgeFill(order.source, sellToken, buyToken, sellAmount, boughtAmount);
    }
}
