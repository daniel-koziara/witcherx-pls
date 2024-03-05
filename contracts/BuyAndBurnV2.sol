// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./openzeppelin/security/ReentrancyGuard.sol";

import "../libs/constantBnB.sol";
import "../libs/TransferHelper.sol";
import "../libs/FullMath.sol";

import "../interfaces/IWPLS.sol";
import "../interfaces/IWITCHERX.sol";
import "../interfaces/IPULSEX.sol";

contract BuyAndBurnV2 is ReentrancyGuard {
    /** @dev genesis timestamp */
    uint256 private immutable i_genesisTs;

    /** @dev owner address */
    address private s_ownerAddress;

    /** @dev tracks total weth used for buyandburn */
    uint256 private s_totalWplsBuyAndBurn;

    /** @dev tracks witcher burned through buyandburn */
    uint256 private s_totalWitcherBuyAndBurn;

    /** @dev tracks current per swap cap */
    uint256 private s_capPerSwap;

    /** @dev tracks timestamp of the last buynburn was called */
    uint256 private s_lastCallTs;

    /** @dev slippage amount between 0 - 50 */
    uint256 private s_slippage;

    /** @dev buynburn interval in seconds */
    uint256 private s_interval;

    address private s_witcherxAddress;

    InitialLPCreated private s_initialLiquidityCreated;

    address public WITCHERX_ADDRESS;
    IPulseXRouter public pulseXRouter;
    address public pulseXPair;

    event BoughtAndBurned(
        uint256 indexed weth,
        uint256 indexed witcher,
        address indexed caller
    );
    event CollectedFees(
        uint256 indexed weth,
        uint256 indexed witcher,
        address indexed caller
    );

    constructor() {
        i_genesisTs = block.timestamp;
        s_ownerAddress = msg.sender;
        s_capPerSwap = 1 ether;
        s_slippage = 5;
        s_interval = 60;

        pulseXRouter = IPulseXRouter(0x165C3410fC91EF562C50559f7d2289fEbed552d9);
		pulseXPair = IPulseXFactory(pulseXRouter.factory()).createPair(address(this), pulseXRouter.WPLS());
    }

    receive() external payable {
        if (msg.sender != WPLS) IWPLS(WPLS).deposit{value: msg.value}();
    }

    function createInitialLiquidity() public {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        if (s_initialLiquidityCreated == InitialLPCreated.YES) return;
        require(getWplsBalance(address(this)) >= INITIAL_LP_WPLS, "Need more WPLS");

        s_initialLiquidityCreated = InitialLPCreated.YES;


        IWITCHERX(s_witcherxAddress).mintLPTokens();
        pulseXRouter.addLiquidityETH{value: INITIAL_LP_WPLS}(
            s_witcherxAddress,
            INITAL_LP_TOKENS,
            0, 
            0,
            address(this),
            block.timestamp
        );
    }

    /** @notice remove owner */
    function renounceOwnership() public {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        s_ownerAddress = address(0);
    }

    /** @notice set new owner address. Only callable by owner address.
     * @param ownerAddress new owner address
     */
    function setOwnerAddress(address ownerAddress) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(ownerAddress != address(0), "InvalidAddress");
        s_ownerAddress = ownerAddress;
    }

    function setWitcherxAddress(address _witcherxAddress) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        WITCHERX_ADDRESS = _witcherxAddress;
    }

    /**
     * @notice set weth cap amount per buynburn call. Only callable by owner address.
     * @param amount amount in 18 decimals
     */
    function setCapPerSwap(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        s_capPerSwap = amount;
    }

    /**
     * @notice set slippage % for buynburn minimum received amount. Only callable by owner address.
     * @param amount amount from 0 - 50
     */
    function setSlippage(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(amount >= 5 && amount <= 15, "5-15_Only");
        s_slippage = amount;
    }

    /**
     * @notice set buynburn call interval in seconds. Only callable by owner address.
     * @param secs amount in seconds
     */
    function setBuynBurnInterval(uint256 secs) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(
            secs >= MIN_INTERVAL_SECONDS && secs <= MAX_INTERVAL_SECONDS,
            "1m-12h_Only"
        );
        s_interval = secs;
    }

    /** @notice burn all Witcher in BuyAndBurn address */
    function burnLPWitcher() public {
        IWITCHERX(WITCHERX_ADDRESS).burnLPTokens();
    }

    /** @notice buy and burn Witcher from pulsex pool */
    function buynBurn() public nonReentrant {
        //prevent contract accounts (bots) from calling this function
        require(msg.sender == tx.origin, "InvalidCaller");
        //a minium gap of 1 min between each call
        require(block.timestamp - s_lastCallTs > s_interval, "IntervalWait");
        s_lastCallTs = block.timestamp;

        uint256 wplsAmount = getWplsBalance(address(this));
        require(wplsAmount != 0, "NoAvailableFunds");

        uint256 wethCap = s_capPerSwap;
        if (wplsAmount > wethCap) wplsAmount = wethCap;

        uint256 incentiveFee = (wplsAmount * INCENTIVE_FEE) /
            INCENTIVE_FEE_PERCENT_BASE;
        IWPLS(WPLS).withdraw(incentiveFee);

        wplsAmount -= incentiveFee;
        _swapWPLSForWitcher(wplsAmount);
        TransferHelper.safeTransferETH(payable(msg.sender), incentiveFee);
    }

    function setTitanContractAddress(address witcherxAddress) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(s_witcherxAddress == address(0), "CannotResetAddress");
        require(witcherxAddress != address(0), "InvalidAddress");
        s_witcherxAddress = witcherxAddress;
    }


    // ==================== Private Functions =======================================
    /** @dev call uniswap swap function to swap weth for witcher, then burn all witcher
     * @param amountWPLS weth amount
     */
    function _swapWPLSForWitcher(uint256 amountWPLS) private {
        
        uint256 plsBalanceBefore = IWPLS(WPLS).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pulseXRouter.WPLS();
		
        // _approve(address(this), address(pulseXRouter), amountWPLS);
        pulseXRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountWPLS,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 plsBalanceResult = IWPLS(WPLS).balanceOf(address(this)) - plsBalanceBefore;



        s_totalWitcherBuyAndBurn += plsBalanceResult;
        burnLPWitcher();
        emit BoughtAndBurned(amountWPLS, plsBalanceResult, msg.sender);
    }

    /** @notice get contract ETH balance
     * @return balance contract ETH balance
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /** @notice get WPLS balance for speciifed address
     * @param account address
     * @return balance WPLS balance
     */
    function getWplsBalance(address account) public view returns (uint256) {
        return IWPLS(WPLS).balanceOf(account);
    }

    /** @notice get witcher balance for speicifed address
     * @param account address
     */
    function getWitcherBalance(address account) public view returns (uint256) {
        return IWITCHERX(WITCHERX_ADDRESS).balanceOf(account);
    }

    /** @notice get buy and burn current contract day
     * @return day current contract day
     */
    function getCurrentContractDay() public view returns (uint256) {
        return ((block.timestamp - i_genesisTs) / SECONDS_IN_DAY) + 1;
    }

    /** @notice get cap amount per buy and burn
     * @return cap amount
     */
    function getWethBuyAndBurnCap() public view returns (uint256) {
        return s_capPerSwap;
    }

    /** @notice get buynburn slippage
     * @return slippage
     */
    function getSlippage() public view returns (uint256) {
        return s_slippage;
    }

    /** @notice get the buynburn interval between each call in seconds
     * @return seconds
     */
    function getBuynBurnInterval() public view returns (uint256) {
        return s_interval;
    }

    /** @notice since burnLPTokens in WitcherX reads the BuyAndBurn CA, WitcherX in V1 will not be burned when CA we migrate to V2,
     * so we just have remove the supply owned by V1
     * @return return the actual total supply
     */
    function totalWitcherXLiquidSupply() public view returns (uint256) {
        return IWITCHERX(WITCHERX_ADDRESS).totalSupply();
    }

    // ==================== BuyAndBurnV2 Getters =======================================
    /** @notice get buy and burn funds (exclude weth fees)
     * @return amount weth amount
     */
    function getBuyAndBurnFundsV2() public view returns (uint256) {
        return getWplsBalance(address(this));
    }

    /** @notice get total wpls amount used to buy and burn (exclude wpls fees)
     * @return amount total wpls amount
     */
    function getTotalWplsBuyAndBurnV2() public view returns (uint256) {
        return s_totalWplsBuyAndBurn;
    }

    /** @notice get total witcher amount burned from all buy and burn
     * @return amount total witcher amount
     */
    function getTotalWitcherBuyAndBurnV2() public view returns (uint256) {
        return s_totalWitcherBuyAndBurn;
    }
}
