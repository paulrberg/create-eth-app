/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Compound?utm=code
  */
  
  // SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./JumpRateModelV2.sol";

/**
  * @title Compound's DAIInterestRateModel Contract (version 3)
  * @author Compound (modified by Dharma Labs)
  * @notice The parameterized model described in section 2.4 of the original Compound Protocol whitepaper.
  * Version 3 modifies the interest rate model in Version 2 by increasing the initial "gap" or slope of
  * the model prior to the "kink" from 2% to 4%, and enabling updateable parameters.
  */
contract DAIInterestRateModelV3 is JumpRateModelV2 {
    uint256 private constant BASE = 1e18;
    uint256 private constant RAY_BASE = 1e27;
    uint256 private constant RAY_TO_BASE_SCALE = 1e9;
    uint256 private constant SECONDS_PER_BLOCK = 15;

    /**
     * @notice The additional margin per block separating the base borrow rate from the roof.
     */
    uint public gapPerBlock;

    /**
     * @notice The assumed (1 - reserve factor) used to calculate the minimum borrow rate (reserve factor = 0.05)
     */
    uint public constant assumedOneMinusReserveFactorMantissa = 0.95e18;

    PotLike pot;
    JugLike jug;

    /**
     * @notice Construct an interest rate model
     * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
     * @param kink_ The utilization point at which the jump multiplier is applied
     * @param pot_ The address of the Dai pot (where DSR is earned)
     * @param jug_ The address of the Dai jug (where SF is kept)
     * @param owner_ The address of the owner, i.e. the Timelock contract (which has the ability to update parameters directly)
     */
    constructor(uint jumpMultiplierPerYear, uint kink_, address pot_, address jug_, address owner_) JumpRateModelV2(0, 0, jumpMultiplierPerYear, kink_, owner_) public {
        gapPerBlock = 4e16 / blocksPerYear;
        pot = PotLike(pot_);
        jug = JugLike(jug_);
        poke();
    }

    /**
     * @notice External function to update the parameters of the interest rate model
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by BASE). For DAI, this is calculated from DSR and SF. Input not used.
     * @param gapPerYear The Additional margin per year separating the base borrow rate from the roof. (scaled by BASE)
     * @param jumpMultiplierPerYear The jumpMultiplierPerYear after hitting a specified utilization point
     * @param kink_ The utilization point at which the jump multiplier is applied
     */
    function updateJumpRateModel(uint baseRatePerYear, uint gapPerYear, uint jumpMultiplierPerYear, uint kink_) override external {
        require(msg.sender == owner, "only the owner may call this function.");
        gapPerBlock = gapPerYear / blocksPerYear;
        updateJumpRateModelInternal(0, 0, jumpMultiplierPerYear, kink_);
        poke();
    }

    /**
     * @notice Calculates the current supply interest rate per block including the Dai savings rate
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amnount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by BASE)
     */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) override public view returns (uint) {
        uint protocolRate = super.getSupplyRate(cash, borrows, reserves, reserveFactorMantissa);

        uint underlying = cash + borrows - reserves;
        if (underlying == 0) {
            return protocolRate;
        } else {
            uint cashRate = cash * dsrPerBlock() / underlying;
            return cashRate + protocolRate;
        }
    }

    /**
     * @notice Calculates the Dai savings rate per block
     * @return The Dai savings rate per block (as a percentage, and scaled by BASE)
     */
    function dsrPerBlock() public view returns (uint) {
        return (pot.dsr() - RAY_BASE) // scaled RAY_BASE aka RAY, and includes an extra "ONE" before subtraction
            / RAY_TO_BASE_SCALE // descale to BASE
            * SECONDS_PER_BLOCK; // seconds per block
    }

    /**
     * @notice Resets the baseRate and multiplier per block based on the stability fee and Dai savings rate
     */
    function poke() public {
        (uint duty, ) = jug.ilks("ETH-A");
        uint stabilityFeePerBlock = (duty + jug.base() - RAY_BASE) / RAY_TO_BASE_SCALE * SECONDS_PER_BLOCK;

        // We ensure the minimum borrow rate >= DSR / (1 - reserve factor)
        baseRatePerBlock = dsrPerBlock() * BASE / assumedOneMinusReserveFactorMantissa;

        // The roof borrow rate is max(base rate, stability fee) + gap, from which we derive the slope
        if (baseRatePerBlock < stabilityFeePerBlock) {
            multiplierPerBlock = (stabilityFeePerBlock - baseRatePerBlock + gapPerBlock) * BASE / kink;
        } else {
            multiplierPerBlock = gapPerBlock * BASE / kink;
        }

        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
    }
}


/*** Maker Interfaces ***/

interface PotLike {
    function chi() external view returns (uint);
    function dsr() external view returns (uint);
    function rho() external view returns (uint);
    function pie(address) external view returns (uint);
    function drip() external returns (uint);
    function join(uint) external;
    function exit(uint) external;
}

contract JugLike {
    // --- Data ---
    struct Ilk {
        uint256 duty;
        uint256  rho;
    }

    mapping (bytes32 => Ilk) public ilks;
    uint256 public base;
}
