// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IWITCHERX {
    function balanceOf(address account) external view returns (uint256);

    function getBalance() external;

    function mintLPTokens() external;

    function burnLPTokens() external;

    function totalSupply() external view returns (uint256);
}
