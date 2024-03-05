// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../contracts/openzeppelin/token/ERC20/IERC20.sol";

interface IWITCHERX is IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function getBalance() external;

    function mintLPTokens() external;

    function burnLPTokens() external;

    function totalSupply() external view returns (uint256);
}
