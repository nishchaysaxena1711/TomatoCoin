//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../token/Tomato.sol";

contract TomatoSale is Ownable, Tomato {

    event Contribution(address owner, uint etherAmount);
    event ReleaseTokens(address owner, uint etherAmount);

    mapping(address => bool) whitelistedAddresses;
    mapping(address => uint) etherContributions;

    uint constant GOAL = 30000 ether;
    uint constant PHASE_SEED_MAX_CONTRIBUTION_LIMIT = 15000 ether;
    uint constant PHASE_SEED_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT = 1500 ether;
    uint constant PHASE_GENERAL_MAX_CONTRIBUTION_LIMIT = GOAL;
    uint constant PHASE_GENERAL_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT = 1000 ether;

    Tomato public tomatoToken;
    uint private totalEtherRaised;
    bool public taxEnabled;
    bool public fundRaisingEnabled;

    constructor() {
        phase = PHASE.SEED;
        admin = msg.sender;
    }

    function addAddressToWhitelist(address whitelistAddress) external onlyOwner {
        whitelistedAddresses[whitelistAddress] = true;
    }

    function removeAdressFromWhitelist(address whitelistAddress) external onlyOwner {
        whitelistedAddresses[whitelistAddress] = false;
    }

    function movePhaseForward() external onlyOwner {
        if (phase == PHASE.SEED) {
            phase = PHASE.GENERAL;
        } else if (phase == PHASE.GENERAL) {
            phase = PHASE.OPEN;
            transferTomatoTokens();
        }
    }

    function toggleTaxOnTxn() external onlyOwner {
        taxEnabled = !taxEnabled;
        if (taxEnabled) {
            emit TomatoSaleTaxEnabled();
        } else {
            emit TomatoSaleTaxDisabled();
        }
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
            require(tokenSupply <= TOTAL_SUPPLY, "No tomato coins are available");
        }

        uint etherAmount = msg.value;
        // Note: Need to check with Gilbert when to apply tax
        if (taxEnabled) {
            etherAmount -= calculateTax(etherAmount);
        }

        mint(msg.sender, ((etherAmount / 5) * 10 ** 18));

        etherContributions[msg.sender] += etherAmount;
        totalEtherRaised += etherAmount;

        emit Contribution(msg.sender, etherAmount);
    }

    function calculateTax(uint _amount) private pure returns(uint) {
        return TAX_RATE * _amount;
    }

    function transferTomatoTokens() private view {
        require(phase == PHASE.OPEN);
        // TODO: Logic to transfer tokens
    }
    
}
