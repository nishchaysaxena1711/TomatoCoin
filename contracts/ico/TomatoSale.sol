//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "../token/Tomato.sol";

// // To fix this error: TypeError: Member "mint" not found or not visible after argument-dependent lookup in contract IERC20.
// interface IERC20TomatoCoin is IERC20 {
//     function mint(address _to, uint256 _amount) external;
// }

contract TomatoSale is Initializable, OwnableUpgradeable {

    enum PHASE {
        SEED,
        GENERAL,
        OPEN
    }

    event Contribution(address owner, uint etherAmount);
    event Redeem(address owner, uint noOfTomatoCoins);
    event TomatoSaleStatus(bool status);

    mapping(address => bool) whitelistedAddresses;
    mapping(address => uint) etherContributions;

    uint constant EXCHANGE_RATE = 5;
    uint constant GOAL = 30000 ether;
    uint constant PHASE_SEED_MAX_CONTRIBUTION_LIMIT = 15000 ether;
    uint constant PHASE_SEED_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT = 1500 ether;
    uint constant PHASE_GENERAL_MAX_CONTRIBUTION_LIMIT = GOAL;
    uint constant PHASE_GENERAL_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT = 1000 ether;

    Tomato private tomatoCoin;
    uint public totalEtherRaised;
    PHASE public phase;
    bool public fundRaisingEnabled;

    // Error: Contract `TomatoSale` is not upgrade safe contracts/ico/TomatoSale.sol:24: Contract `TomatoSale` has a constructor. Define an initializer instead
    // To fix above issue, commented out constructor and added initializer
    // constructor() {
    //     phase = PHASE.SEED;
    //     admin = msg.sender;
    // }

    function initialize(address _tomatoCoin) public initializer {
        __Ownable_init();
        phase = PHASE.SEED;
        tomatoCoin = Tomato(_tomatoCoin);
    }

    function modifyWhitelistAddresses(address whitelistAddress, bool canContribute) external onlyOwner {
        whitelistedAddresses[whitelistAddress] = canContribute;
    }

    function movePhaseForward() external onlyOwner {
        require(phase != PHASE.OPEN);
        if (phase == PHASE.SEED) {
            phase = PHASE.GENERAL;
        } else if (phase == PHASE.GENERAL) {
            phase = PHASE.OPEN;
        }
    }

    function redeemTomatoTokens() external payable {
        require(phase == PHASE.OPEN, "Redemption available in Open Phase");
        require(etherContributions[msg.sender] > 0, "You do not have enough coins for redemption");

        uint amount = etherContributions[msg.sender];
        etherContributions[msg.sender] = 0;

        tomatoCoin.mint(msg.sender, amount * EXCHANGE_RATE);

        emit Redeem(msg.sender, amount * EXCHANGE_RATE);
    }

    function toggleFundRaising() external onlyOwner {
        fundRaisingEnabled = !fundRaisingEnabled;
        emit TomatoSaleStatus(fundRaisingEnabled);
    }

    function buyTomatoTokens() external payable {
        require(fundRaisingEnabled == true, "Tomato token sale must be active");
        require(msg.value > 0, "Contribution should be greater than 0");

        uint callerBalance = etherContributions[msg.sender];
        uint remainingBalance;
        uint amount = msg.value;

        if (phase == PHASE.SEED) {
            require(totalEtherRaised <= PHASE_SEED_MAX_CONTRIBUTION_LIMIT);
            require(whitelistedAddresses[msg.sender] == true, "Address is not whitelisted for sale in seed phase");
            require(callerBalance <= (PHASE_SEED_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT / 10 ** 18), "Individual contributon cannot be greater than 1500 ether");

            remainingBalance = (PHASE_SEED_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT - callerBalance) / 10 ** 18;
            if (amount > remainingBalance) {
                amount = remainingBalance;
            }
        } else if (phase == PHASE.GENERAL) {
            require(totalEtherRaised <= PHASE_GENERAL_MAX_CONTRIBUTION_LIMIT);
            require(callerBalance <= (PHASE_GENERAL_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT / 10 ** 18), "Individual contributon cannot be greater than 1000 ether");

            remainingBalance = (PHASE_GENERAL_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT - callerBalance) / 10 ** 18;
            if (amount > remainingBalance) {
                amount = remainingBalance;
            }
        } else if (phase == PHASE.OPEN) {
            require((totalEtherRaised * 5) <= 500000, "No tomato coins are available");
        }

        etherContributions[msg.sender] += amount;
        totalEtherRaised += amount;

        emit Contribution(msg.sender, amount);
    }
    
}
