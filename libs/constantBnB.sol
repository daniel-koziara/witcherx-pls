// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


enum InitialLPCreated {
    NO,
    YES
}

address constant TITANX_WETH_POOL = 0xc45A81BC23A64eA556ab4CdF08A86B61cdcEEA8b;
address constant UNISWAPV3FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
address constant WPLS = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;

uint256 constant INITIAL_LP_WPLS = 100 ether;

uint256 constant SECONDS_IN_DAY = 86400;

uint256 constant INITIAL_LP_TOKENS = 100_000_000_000 ether;


uint24 constant POOLFEE1PERCENT = 10000; //1% Fee
uint160 constant MIN_SQRT_RATIO = 4295128739;
uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

uint256 constant INCENTIVE_FEE = 3300;
uint256 constant INCENTIVE_FEE_PERCENT_BASE = 1_000_000;

uint256 constant MIN_INTERVAL_SECONDS = 60;
uint256 constant MAX_INTERVAL_SECONDS = 43200; //12 hours
