// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IPulseXFactory {
   function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPulseXRouter {
   function factory() external pure returns (address);
   function WPLS() external pure returns (address);
   function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
   function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}
