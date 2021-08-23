//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// To fix this error: TypeError: Member "mint" not found or not visible after argument-dependent lookup in contract IERC20.
interface IERC20TomatoCoin is IERC20 {
    function mint(address _to, uint256 _amount) external;
}

contract TomatoSale is Initializable, OwnableUpgradeable {

    enum PHASE {
        SEED,
        GENERAL,
        OPEN
    }

    event Contribution(address owner, uint etherAmount);
    event Redeem(address owner, uint noOfTomatoCoins);
    event TomatoSalePaused();
    event TomatoSaleResumed();

    mapping(address => bool) whitelistedAddresses;
    mapping(address => uint) etherContributions;

    uint constant EXCHANGE_RATE = 5;
    uint constant GOAL = 30000 ether;
    uint constant PHASE_SEED_MAX_CONTRIBUTION_LIMIT = 15000 ether;
    uint constant PHASE_SEED_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT = 1500 ether;
    uint constant PHASE_GENERAL_MAX_CONTRIBUTION_LIMIT = GOAL;
    uint constant PHASE_GENERAL_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT = 1000 ether;

    IERC20TomatoCoin private tomatoCoin;
    uint private totalEtherRaised;
    PHASE public phase;
    bool public fundRaisingEnabled;

    // Error: Contract `TomatoSale` is not upgrade safe
    // contracts/ico/TomatoSale.sol:24: Contract `TomatoSale` has a constructor. Define an initializer instead

    // To fix above issue, commented out constructor and added initializer
    // constructor() {
    //     phase = PHASE.SEED;
    //     admin = msg.sender;
    // }
    function initialize(address _tomatoCoin) public initializer {
        __Ownable_init();
        phase = PHASE.SEED;
        tomatoCoin = IERC20TomatoCoin(_tomatoCoin);
    }

    function addAddressToWhitelist(address whitelistAddress) external onlyOwner {
        whitelistedAddresses[whitelistAddress] = true;
    }

    function removeAdressFromWhitelist(address whitelistAddress) external onlyOwner {
        whitelistedAddresses[whitelistAddress] = false;
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
        require(phase != PHASE.OPEN);
        require(etherContributions[msg.sender] > 0);

        etherContributions[msg.sender] = 0;

        tomatoCoin.mint(msg.sender, etherContributions[msg.sender] * EXCHANGE_RATE);

        emit Redeem(msg.sender, etherContributions[msg.sender] * EXCHANGE_RATE);
    }

    function toggleFundRaising() external onlyOwner {
        fundRaisingEnabled = !fundRaisingEnabled;
        if (fundRaisingEnabled) {
            emit TomatoSaleResumed();
        } else {
            emit TomatoSalePaused();
        }
    }

    function buyTomatoTokens() public payable {
        require(fundRaisingEnabled == true, "Tomato token sale must be active");

        uint tokenSupply = totalEtherRaised;
        uint callerBalance = etherContributions[msg.sender];

        if (phase == PHASE.SEED) {
            require(tokenSupply <= PHASE_SEED_MAX_CONTRIBUTION_LIMIT);
            require(whitelistedAddresses[msg.sender] == true, "Address is not whitelisted for sale in seed phase");
            require(callerBalance <= PHASE_SEED_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT, "Individual contributon cannot be greater than 1500 ether");
        } else if (phase == PHASE.GENERAL) {
            require(tokenSupply <= PHASE_GENERAL_MAX_CONTRIBUTION_LIMIT);
            require(callerBalance <= PHASE_GENERAL_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT, "Individual contributon cannot be greater than 1000 ether");
        } else if (phase == PHASE.OPEN) {
            require(tokenSupply <= 500000, "No tomato coins are available");
        }

        etherContributions[msg.sender] += msg.value;
        totalEtherRaised += msg.value;

        emit Contribution(msg.sender, msg.value);
    }

    function getPhase() public view returns (PHASE) {
        return phase;
    }
    
}
