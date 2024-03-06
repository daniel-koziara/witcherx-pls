// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// ===================== common ==========================================
uint256 constant SECONDS_IN_DAY = 86400;
uint256 constant SCALING_FACTOR_1e3 = 1e3;
uint256 constant SCALING_FACTOR_1e6 = 1e6;
uint256 constant SCALING_FACTOR_1e7 = 1e7;
uint256 constant SCALING_FACTOR_1e11 = 1e11;
uint256 constant SCALING_FACTOR_1e18 = 1e18;

// ===================== WITCHERX ==========================================
uint256 constant PERCENT_TO_BUY_AND_BURN = 73_00;
uint256 constant PERCENT_TO_CYCLE_PAYOUTS = 17_00;
uint256 constant PERCENT_TO_BURN_PAYOUTS = 7_00;
uint256 constant PERCENT_TO_GENESIS = 3_00;

uint256 constant INCENTIVE_FEE_PERCENT = 3300;
uint256 constant INCENTIVE_FEE_PERCENT_BASE = 1_000_000;

uint256 constant INITAL_LP_TOKENS = 100_000_000_000 ether;

// ===================== globalInfo ==========================================
//Witcher Supply Variables
uint256 constant START_MAX_MINTABLE_PER_DAY = 8_000_000 ether;
uint256 constant CAPPED_MIN_DAILY_WITCHER_MINTABLE = 800 ether;
uint256 constant DAILY_SUPPLY_MINTABLE_REDUCTION = 99_65;

//EAA Variables
uint256 constant EAA_START = 10 * SCALING_FACTOR_1e6;
uint256 constant EAA_BONUSE_FIXED_REDUCTION_PER_DAY = 28_571;
uint256 constant EAA_END = 0;
uint256 constant MAX_BONUS_DAY = 350;

//Mint Cost Variables
uint256 constant START_MAX_MINT_COST = 5_000_000 ether;
uint256 constant CAPPED_MAX_MINT_COST = 50_000_000 ether;
uint256 constant DAILY_MINT_COST_INCREASE_STEP = 100_08;

//mintPower Bonus Variables
uint256 constant START_MINTPOWER_INCREASE_BONUS = 35 * SCALING_FACTOR_1e7; //starts at 35 with 1e7 scaling factor
uint256 constant CAPPED_MIN_MINTPOWER_BONUS = 35 * SCALING_FACTOR_1e3; //capped min of 0.0035 * 1e7 = 35 * 1e3
uint256 constant DAILY_MINTPOWER_INCREASE_BONUS_REDUCTION = 99_65;

//Share Rate Variables
uint256 constant START_SHARE_RATE = 800 ether;
uint256 constant DAILY_SHARE_RATE_INCREASE_STEP = 100_03;
uint256 constant CAPPED_MAX_RATE = 2_800 ether;

//Cycle Variables
uint256 constant DAY1 = 1;
uint256 constant DAY7 = 7;
uint256 constant DAY14 = 14;
uint256 constant DAY28 = 28;
uint256 constant DAY56 = 56;
uint256 constant CYCLE_1_PERCENT = 28_00;
uint256 constant CYCLE_7_PERCENT = 28_00;
uint256 constant CYCLE_14_PERCENT = 18_00;
uint256 constant CYCLE_28_PERCENT = 18_00;
uint256 constant CYCLE_56_PERCENT = 8_00;
uint256 constant PERCENT_BPS = 100_00;

// ===================== mintInfo ==========================================
uint256 constant MAX_MINT_POWER_CAP = 100;
uint256 constant MAX_MINT_LENGTH = 88;
uint256 constant MIN_MINT_LENGTH = 8;
uint256 constant CLAIM_MINT_GRACE_PERIOD = 7;
uint256 constant MAX_BATCH_MINT_COUNT = 100;
uint256 constant MAX_MINT_PER_WALLET = 1000;
uint256 constant MAX_BURN_AMP_BASE = 80 * 1e9 * 1 ether;
uint256 constant MAX_BURN_AMP_PERCENT = 8 ether;
uint256 constant MINT_DAILY_REDUCTION = 11;

// ===================== stakeInfo ==========================================
uint256 constant MAX_STAKE_PER_WALLET = 1000;
uint256 constant MIN_STAKE_LENGTH = 28;
uint256 constant MAX_STAKE_LENGTH = 3500;
uint256 constant END_STAKE_GRACE_PERIOD = 7;

/* Stake Longer Pays Better bonus */
uint256 constant LPB_MAX_DAYS = 2888;
uint256 constant LPB_PER_PERCENT = 825;

/* Stake Bigger Pays Better bonus */
uint256 constant BPB_MAX_WITCHER = 100 * 1e9 * SCALING_FACTOR_1e18; //100 billion
uint256 constant BPB_PER_PERCENT = 1_250_000_000_000 * SCALING_FACTOR_1e18;

// ===================== burnInfo ==========================================
uint256 constant MAX_BURN_REWARD_PERCENT = 8;
