// SPDX-License-Identifier: MIT
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

    /** @dev tracks total wpls used for buyandburn */
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

    IPulseXRouter public pulseXRouter;
    address public pulseXPair;

    event BoughtAndBurned(
        uint256 indexed wpls,
        uint256 indexed witcher,
        address indexed caller
    );
    event CollectedFees(
        uint256 indexed wpls,
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
        require(IWPLS(WPLS).balanceOf(address(this)) >= INITIAL_LP_WPLS, "Need more PLS");

        if (s_initialLiquidityCreated == InitialLPCreated.YES) return;

        s_initialLiquidityCreated = InitialLPCreated.YES;

        IWITCHERX(s_witcherxAddress).mintLPTokens();


        IWPLS(WPLS).approve(address(pulseXRouter), INITIAL_LP_WPLS);
        IWITCHERX(s_witcherxAddress).approve(address(pulseXRouter), INITIAL_LP_TOKENS);

        pulseXRouter.addLiquidityETH{value: INITIAL_LP_WPLS}(
            s_witcherxAddress,
            INITIAL_LP_TOKENS,
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

    /**
     * @notice set wpls cap amount per buynburn call. Only callable by owner address.
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
        IWITCHERX(s_witcherxAddress).burnLPTokens();
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

        uint256 wplsCap = s_capPerSwap;
        if (wplsAmount > wplsCap) wplsAmount = wplsCap;


        _swapWPLSForWitcher(wplsAmount);
    }

    function setWitcherContractAddress(address witcherxAddress) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(s_witcherxAddress == address(0), "CannotResetAddress");
        require(witcherxAddress != address(0), "InvalidAddress");
        s_witcherxAddress = witcherxAddress;
    }


    // ==================== Private Functions =======================================
    /** @dev call uniswap swap function to swap wpls for witcher, then burn all witcher
     * @param amountWPLS wpls amount
     */
    function _swapWPLSForWitcher(uint256 amountWPLS) private {
        
        uint256 witcherBalanceBefore = IWITCHERX(s_witcherxAddress).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = pulseXRouter.WPLS();
        path[1] = address(s_witcherxAddress);

        IWPLS(WPLS).approve(address(pulseXRouter), amountWPLS);
		
        pulseXRouter.swapExactTokensForTokens(
            amountWPLS,
            0,
            path,
            address(this),
            block.timestamp + 120
        );
        
        uint256 witcherBalanceAfter = IWITCHERX(s_witcherxAddress).balanceOf(address(this));
        uint256 witcherReceived = witcherBalanceAfter - witcherBalanceBefore;


        s_totalWitcherBuyAndBurn += witcherReceived;
        burnLPWitcher();
        emit BoughtAndBurned(amountWPLS, witcherReceived, msg.sender);
    }

    /** @notice get contract PLS balance
     * @return balance contract PLS balance
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
        return IWITCHERX(s_witcherxAddress).balanceOf(account);
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
    function getWplsBuyAndBurnCap() public view returns (uint256) {
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
        return IWITCHERX(s_witcherxAddress).totalSupply();
    }

    // ==================== BuyAndBurnV2 Getters =======================================
    /** @notice get buy and burn funds (exclude wpls fees)
     * @return amount wpls amount
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
