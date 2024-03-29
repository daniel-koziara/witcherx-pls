// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libs/constant.sol";
import "../libs/enum.sol";

/**
 * @title BurnInfo
 * @dev this contract is meant to be inherited into main contract
 * @notice It has the variables and functions specifically for tracking burn amount and reward
 */

abstract contract BurnInfo {
    //Variables
    //track the total witcher burn amount
    uint256 private s_totalWitcherBurned;

    //mappings
    //track wallet address -> total witcher burn amount
    mapping(address => uint256) private s_userBurnAmount;
    //track contract/project address -> total witcher burn amount
    mapping(address => uint256) private s_project_BurnAmount;
    //track contract/project address, wallet address -> total witcher burn amount
    mapping(address => mapping(address => uint256)) private s_projectUser_BurnAmount;

    /** @dev cycleIndex is increased when triggerPayouts() was called successfully
     * so we track data in current cycleIndex + 1 which means tracking for the next cycle payout
     * cycleIndex is passed from the WITCHERX contract during function call
     */
    //track cycleIndex + 1 -> total burn amount
    mapping(uint256 => uint256) private s_cycle28TotalBurn;
    //track address, cycleIndex + 1 -> total burn amount
    mapping(address => mapping(uint256 => uint256)) private s_userCycle28TotalBurn;
    //track cycleIndex + 1 -> burn payout per token
    mapping(uint256 => uint256) private s_cycle28BurnPayoutPerToken;

    //events
    /** @dev log user burn witcher event
     * project can be address(0) if user burns Witcher directly from Witcher contract
     * burnPoolCycleIndex is the cycle 28 index, which reuse the same index as Day 28 cycle index
     * witcherSource 0=Liquid, 1=Mint, 2=Stake
     */
    event WitcherBurned(
        address indexed user,
        address indexed project,
        uint256 indexed burnPoolCycleIndex,
        uint256 amount,
        BurnSource witcherSource
    );

    //functions
    /** @dev update the burn amount in each 28-cylce for user and project (if any)
     * @param user wallet address
     * @param project contract address
     * @param amount witcher amount burned
     * @param cycleIndex cycle payout triggered index
     */
    function _updateBurnAmount(
        address user,
        address project,
        uint256 amount,
        uint256 cycleIndex,
        BurnSource source
    ) internal {
        s_userBurnAmount[user] += amount;
        s_totalWitcherBurned += amount;
        s_cycle28TotalBurn[cycleIndex] += amount;
        s_userCycle28TotalBurn[user][cycleIndex] += amount;

        if (project != address(0)) {
            s_project_BurnAmount[project] += amount;
            s_projectUser_BurnAmount[project][user] += amount;
        }

        emit WitcherBurned(user, project, cycleIndex, amount, source);
    }

    /**
     * @dev calculate burn reward per witcher burned based on total reward / total witcher burned in current cycle
     * @param cycleIndex wallet address
     * @param reward contract address
     * @param cycleBurnAmount witcher amount burned
     */
    function _calculateCycleBurnRewardPerToken(
        uint256 cycleIndex,
        uint256 reward,
        uint256 cycleBurnAmount
    ) internal {
        //add 18 decimals to reward for better precision in calculation
        s_cycle28BurnPayoutPerToken[cycleIndex] = (reward * SCALING_FACTOR_1e18) / cycleBurnAmount;
    }

    /** @dev returned value is in 18 decimals, need to divide it by 1e18 and 100 (percentage) when using this value for reward calculation
     * The burn amplifier percentage is applied to all future mints. Capped at MAX_BURN_AMP_PERCENT (8%)
     * @param user wallet address
     * @return percentage returns percentage value in 18 decimals
     */
    function getUserBurnAmplifierBonus(address user) public view returns (uint256) {
        uint256 userBurnTotal = getUserBurnTotal(user);
        if (userBurnTotal == 0) return 0;
        if (userBurnTotal >= MAX_BURN_AMP_BASE) return MAX_BURN_AMP_PERCENT;
        return (MAX_BURN_AMP_PERCENT * userBurnTotal) / MAX_BURN_AMP_BASE;
    }

    //views
    /** @notice return total burned witcher amount from all users burn or projects burn
     * @return totalBurnAmount returns entire burned witcher
     */
    function getTotalBurnTotal() public view returns (uint256) {
        return s_totalWitcherBurned;
    }

    /** @notice return user address total burned witcher
     * @return userBurnAmount returns user address total burned witcher
     */
    function getUserBurnTotal(address user) public view returns (uint256) {
        return s_userBurnAmount[user];
    }

    /** @notice return project address total burned witcher amount
     * @return projectTotalBurnAmount returns project total burned witcher
     */
    function getProjectBurnTotal(address contractAddress) public view returns (uint256) {
        return s_project_BurnAmount[contractAddress];
    }

    /** @notice return user address total burned witcher amount via a project address
     * @param contractAddress project address
     * @param user user address
     * @return projectUserTotalBurnAmount returns user address total burned witcher via a project address
     */
    function getProjectUserBurnTotal(
        address contractAddress,
        address user
    ) public view returns (uint256) {
        return s_projectUser_BurnAmount[contractAddress][user];
    }

    /** @notice return cycle28 total burned witcher amount with the specified cycleIndex
     * @param cycleIndex cycle index
     * @return cycle28TotalBurn returns cycle28 total burned witcher amount with the specified cycleIndex
     */
    function getCycleBurnTotal(uint256 cycleIndex) public view returns (uint256) {
        return s_cycle28TotalBurn[cycleIndex];
    }

    /** @notice return cycle28 total burned witcher amount with the specified cycleIndex
     * @param user user address
     * @param cycleIndex cycle index
     * @return cycle28TotalBurn returns cycle28 user address total burned witcher amount with the specified cycleIndex
     */
    function _getUserCycleBurnTotal(
        address user,
        uint256 cycleIndex
    ) internal view returns (uint256) {
        return s_userCycle28TotalBurn[user][cycleIndex];
    }

    /** @notice return cycle28 burn payout per witcher with the specified cycleIndex
     * @param cycleIndex cycle index
     * @return cycle28TotalBurn returns cycle28 burn payout per witcher with the specified cycleIndex
     */
    function getCycleBurnPayoutPerToken(uint256 cycleIndex) public view returns (uint256) {
        return s_cycle28BurnPayoutPerToken[cycleIndex];
    }
}
