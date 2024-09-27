/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Uniswap-V4?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import "Uniswap-V4/forge-std/Test.sol";
import {MockERC20} from "Uniswap-V4/solmate/test/utils/mocks/MockERC20.sol";
import {Vault} from "../../src/Vault.sol";
import {BalanceDelta, toBalanceDelta} from "../../src/types/BalanceDelta.sol";
import {IPoolManager} from "../../src/interfaces/IPoolManager.sol";
import {Currency} from "../../src/types/Currency.sol";
import {PoolKey} from "../../src/types/PoolKey.sol";
import {IVault} from "../../src/interfaces/IVault.sol";
import {SafeCast} from "../../src/pool-bin/libraries/math/SafeCast.sol";
import {IHooks} from "../../src/interfaces/IHooks.sol";

contract VaultPoolManager is Test {
    using SafeCast for uint128;

    uint256 MAX_TOKEN_BALANCE = uint128(type(int128).max);
    MockERC20 public token0;
    MockERC20 public token1;
    Currency public currency0;
    Currency public currency1;

    uint256 public totalMintedCurrency0;
    uint256 public totalMintedCurrency1;

    uint256 public totalFeeCollected0;
    uint256 public totalFeeCollected1;

    enum ActionType {
        Take,
        Settle,
        SettleAndMintRefund,
        SettleFor,
        Mint,
        Burn
    }

    struct Action {
        ActionType actionType;
        uint128 amt0;
        uint128 amt1;
    }

    PoolKey poolKey;
    Vault vault;

    constructor(Vault _vault, MockERC20 _token0, MockERC20 _token1) {
        vault = _vault;
        token0 = _token0;
        token1 = _token1;
        currency0 = Currency.wrap(address(token0));
        currency1 = Currency.wrap(address(token1));

        poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: IPoolManager(address(this)),
            fee: 0,
            parameters: 0x00
        });
    }

    /// @dev In take case, assume user remove liquidity and take token out of vault
    function take(uint256 amt0, uint256 amt1) public {
        amt0 = bound(amt0, 0, MAX_TOKEN_BALANCE);
        amt1 = bound(amt1, 0, MAX_TOKEN_BALANCE);

        // make sure the vault has enough liquidity at very beginning
        settle(amt0, amt1);

        vault.lock(abi.encode(Action(ActionType.Take, uint128(amt0), uint128(amt1))));
    }

    /// @dev In settle case, assume user add liquidity and paying to the vault
    function settle(uint256 amt0, uint256 amt1) public {
        amt0 = bound(amt0, 0, MAX_TOKEN_BALANCE);
        amt1 = bound(amt1, 0, MAX_TOKEN_BALANCE);

        // mint token to VaultPoolManager, so VaultPoolManager can pay to the vault
        token0.mint(address(this), amt0);
        token1.mint(address(this), amt1);
        vault.lock(abi.encode(Action(ActionType.Settle, uint128(amt0), uint128(amt1))));
    }

    /// @dev In settleAndRefund case, assume user add liquidity and paying to the vault
    ///      but theres another folk who minted extra token to the vault
    function settleAndMintRefund(uint256 amt0, uint256 amt1, bool sendToVault) public {
        amt0 = bound(amt0, 0, MAX_TOKEN_BALANCE - 1 ether);
        amt1 = bound(amt1, 0, MAX_TOKEN_BALANCE - 1 ether);

        // someone send some token directly to vault
        if (sendToVault) token0.mint(address(vault), 1 ether);

        // mint token to VaultPoolManager, so VaultPoolManager can pay to the vault
        token0.mint(address(this), amt0);
        token1.mint(address(this), amt1);
        vault.lock(abi.encode(Action(ActionType.SettleAndMintRefund, uint128(amt0), uint128(amt1))));
    }

    /// @dev In settleFor case, assume user is paying for hook
    function settleFor(uint256 amt0, uint256 amt1) public {
        amt0 = bound(amt0, 0, MAX_TOKEN_BALANCE);
        amt1 = bound(amt1, 0, MAX_TOKEN_BALANCE);

        // make sure the vault has enough liquidity at very beginning
        settle(amt0, amt1);

        token0.mint(address(this), amt0);
        token1.mint(address(this), amt1);
        vault.lock(abi.encode(Action(ActionType.SettleFor, uint128(amt0), uint128(amt1))));
    }

    /// @dev In mint case, assume user remove liquidity and mint nft as reciept
    function mint(uint256 amt0, uint256 amt1) public {
        amt0 = bound(amt0, 0, MAX_TOKEN_BALANCE);
        amt1 = bound(amt1, 0, MAX_TOKEN_BALANCE);

        // make sure the vault has enough liquidity at very beginning
        settle(amt0, amt1);

        vault.lock(abi.encode(Action(ActionType.Mint, uint128(amt0), uint128(amt1))));
    }

    /// @dev In burn case, assume user already have minted NFT and want to remove nft
    function burn(uint256 amt0, uint256 amt1) public {
        amt0 = bound(amt0, 0, MAX_TOKEN_BALANCE);
        amt1 = bound(amt1, 0, MAX_TOKEN_BALANCE);

        // pre-req VaultPoolManager minted receipt token
        mint(amt0, amt1);

        // VaultPoolManager burn the nft
        vault.lock(abi.encode(Action(ActionType.Burn, uint128(amt0), uint128(amt1))));
    }

    /// @dev In collectFee case, assume user already have minted NFT and want to remove nft
    function collectFee(uint256 amt0, uint256 amt1, uint256 feeToCollect0, uint256 feeToCollect1) public {
        amt0 = bound(amt0, 0, MAX_TOKEN_BALANCE);
        amt1 = bound(amt1, 0, MAX_TOKEN_BALANCE);

        feeToCollect0 = bound(feeToCollect0, 0, amt0);
        feeToCollect1 = bound(feeToCollect1, 0, amt1);

        // make sure the vault has enough liquidity at very beginning
        settle(amt0, amt1);

        vault.collectFee(currency0, feeToCollect0, makeAddr("protocolFeeRecipient"));
        vault.collectFee(currency1, feeToCollect1, makeAddr("protocolFeeRecipient"));
        totalFeeCollected0 += feeToCollect0;
        totalFeeCollected1 += feeToCollect1;
    }

    /// @dev positive balanceDelta: VaultPoolManager owes to vault
    ///      negative balanceDelta: vault owes to VaultPoolManager
    function lockAcquired(bytes calldata data) external returns (bytes memory) {
        Action memory action = abi.decode(data, (Action));

        if (action.actionType == ActionType.Take) {
            BalanceDelta delta = toBalanceDelta(-(int128(action.amt0)), -(int128(action.amt1)));
            vault.accountPoolBalanceDelta(poolKey, delta, address(this));

            vault.take(currency0, address(this), action.amt0);
            vault.take(currency1, address(this), action.amt1);
        } else if (action.actionType == ActionType.Mint) {
            BalanceDelta delta = toBalanceDelta(-(int128(action.amt0)), -(int128(action.amt1)));
            vault.accountPoolBalanceDelta(poolKey, delta, address(this));

            vault.mint(currency0, address(this), action.amt0);
            vault.mint(currency1, address(this), action.amt1);
            totalMintedCurrency0 += action.amt0;
            totalMintedCurrency1 += action.amt1;
        } else if (action.actionType == ActionType.Settle) {
            BalanceDelta delta = toBalanceDelta(int128(action.amt0), int128(action.amt1));
            vault.accountPoolBalanceDelta(poolKey, delta, address(this));

            token0.transfer(address(vault), action.amt0);
            token1.transfer(address(vault), action.amt1);

            vault.settle(currency0);
            vault.settle(currency1);
        } else if (action.actionType == ActionType.SettleAndMintRefund) {
            BalanceDelta delta = toBalanceDelta(int128(action.amt0), int128(action.amt1));
            vault.accountPoolBalanceDelta(poolKey, delta, address(this));

            token0.transfer(address(vault), action.amt0);
            token1.transfer(address(vault), action.amt1);

            (, uint256 refund0) = vault.settleAndMintRefund(currency0, address(this));
            (, uint256 refund1) = vault.settleAndMintRefund(currency1, address(this));

            totalMintedCurrency0 += refund0;
            totalMintedCurrency1 += refund1;
        } else if (action.actionType == ActionType.SettleFor) {
            // hook cash out the fee ahead
            BalanceDelta delta = toBalanceDelta(int128(action.amt0), int128(action.amt1));
            vault.accountPoolBalanceDelta(poolKey, delta, makeAddr("hook"));

            // transfer hook's fee to user
            vault.settleFor(currency0, makeAddr("hook"), action.amt0);
            vault.settleFor(currency1, makeAddr("hook"), action.amt1);

            // handle user's own deltas
            token0.transfer(address(vault), action.amt0);
            token1.transfer(address(vault), action.amt1);

            vault.settle(currency0);
            vault.settle(currency1);
        } else if (action.actionType == ActionType.Burn) {
            BalanceDelta delta = toBalanceDelta(int128(action.amt0), int128(action.amt1));
            vault.accountPoolBalanceDelta(poolKey, delta, address(this));

            vault.burn(currency0, action.amt0);
            vault.burn(currency1, action.amt1);
            totalMintedCurrency0 -= action.amt0;
            totalMintedCurrency1 -= action.amt1;
        }

        return "";
    }
}

contract VaultInvariant is Test, GasSnapshot {
    VaultPoolManager public vaultPoolManager;
    Vault public vault;
    MockERC20 token0;
    MockERC20 token1;

    function setUp() public {
        vault = new Vault();
        token0 = new MockERC20("TestA", "A", 18);
        token1 = new MockERC20("TestB", "B", 18);
        (token0, token1) = address(token0) > address(token1) ? (token1, token0) : (token0, token1);

        vaultPoolManager = new VaultPoolManager(vault, token0, token1);
        vault.registerPoolManager(address(vaultPoolManager));

        // Only call vaultPoolManager, otherwise all other contracts deployed in setUp will be called
        targetContract(address(vaultPoolManager));

        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = VaultPoolManager.take.selector;
        selectors[1] = VaultPoolManager.mint.selector;
        selectors[2] = VaultPoolManager.settle.selector;
        selectors[3] = VaultPoolManager.burn.selector;
        selectors[4] = VaultPoolManager.settleFor.selector;
        selectors[5] = VaultPoolManager.collectFee.selector;
        selectors[6] = VaultPoolManager.settleAndMintRefund.selector;
        targetSelector(FuzzSelector({addr: address(vaultPoolManager), selectors: selectors}));
    }

    function invariant_TokenbalanceInVaultGeReserveOfVault() public {
        (uint256 amt0Bal, uint256 amt1Bal) = getTokenBalanceInVault();

        assertGe(amt0Bal, vault.reservesOfVault(vaultPoolManager.currency0()));
        assertGe(amt1Bal, vault.reservesOfVault(vaultPoolManager.currency1()));
    }

    function invariant_TokenbalanceInVaultGeReserveOfPoolManagerPlusSurplusToken() public {
        (uint256 amt0Bal, uint256 amt1Bal) = getTokenBalanceInVault();

        uint256 totalMintedCurrency0 = vaultPoolManager.totalMintedCurrency0();
        uint256 totalMintedCurrency1 = vaultPoolManager.totalMintedCurrency1();

        IPoolManager manager = IPoolManager(address(vaultPoolManager));
        assertGe(amt0Bal, vault.reservesOfPoolManager(manager, vaultPoolManager.currency0()) + totalMintedCurrency0);
        assertGe(amt1Bal, vault.reservesOfPoolManager(manager, vaultPoolManager.currency1()) + totalMintedCurrency1);
    }

    function invariant_ReserveOfVaultEqReserveOfPoolManagerPlusSurplusToken() public {
        uint256 totalMintedCurrency0 = vaultPoolManager.totalMintedCurrency0();
        uint256 totalMintedCurrency1 = vaultPoolManager.totalMintedCurrency1();

        IPoolManager manager = IPoolManager(address(vaultPoolManager));
        assertEq(
            vault.reservesOfVault(vaultPoolManager.currency0()),
            vault.reservesOfPoolManager(manager, vaultPoolManager.currency0()) + totalMintedCurrency0
        );
        assertEq(
            vault.reservesOfVault(vaultPoolManager.currency1()),
            vault.reservesOfPoolManager(manager, vaultPoolManager.currency1()) + totalMintedCurrency1
        );
    }

    function invariant_LockDataLengthZero() public {
        uint256 nonZeroDeltaCount = vault.getUnsettledDeltasCount();
        assertEq(nonZeroDeltaCount, 0);
    }

    function invariant_Locker() public {
        address locker = vault.getLocker();
        assertEq(locker, address(0));
    }

    function invariant_TotalMintedCurrency() public {
        uint256 totalMintedCurrency0 = vaultPoolManager.totalMintedCurrency0();
        uint256 totalMintedCurrency1 = vaultPoolManager.totalMintedCurrency1();

        assertEq(totalMintedCurrency0, vault.balanceOf(address(vaultPoolManager), vaultPoolManager.currency0()));
        assertEq(totalMintedCurrency1, vault.balanceOf(address(vaultPoolManager), vaultPoolManager.currency1()));
    }

    function invariant_TotalFeeCollected() public {
        uint256 totalFeeCollected0 = vaultPoolManager.totalFeeCollected0();
        uint256 totalFeeCollected1 = vaultPoolManager.totalFeeCollected1();

        assertEq(totalFeeCollected0, token0.balanceOf(makeAddr("protocolFeeRecipient")));
        assertEq(totalFeeCollected1, token1.balanceOf(makeAddr("protocolFeeRecipient")));
    }

    function invariant_TokenBalanceInVaultGeMinted() public {
        (uint256 amt0Bal, uint256 amt1Bal) = getTokenBalanceInVault();

        assertGe(amt0Bal, vault.balanceOf(address(vaultPoolManager), vaultPoolManager.currency0()));
        assertGe(amt1Bal, vault.balanceOf(address(vaultPoolManager), vaultPoolManager.currency1()));
    }

    function getTokenBalanceInVault() internal view returns (uint256 amt0, uint256 amt1) {
        amt0 = token0.balanceOf(address(vault));
        amt1 = token1.balanceOf(address(vault));
    }
}
