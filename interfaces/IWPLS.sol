// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../contracts/openzeppelin/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWPLS is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}
