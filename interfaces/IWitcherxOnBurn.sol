// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IWitcherxOnBurn {
    function onBurn(address user, uint256 amount) external;
}
