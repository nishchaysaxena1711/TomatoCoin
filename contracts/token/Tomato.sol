//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Tomato is Initializable, ERC20Upgradeable, OwnableUpgradeable {

    event TomatoIcoTaxEnabled();
    event TomatoIcoTaxDisabled();

    string constant TOKEN_NAME = "Tomato";
    string constant TOKEN_SYMBOL = "TMT";
    uint constant TOTAL_SUPPLY = 500000;
    uint constant INITIAL_SUPPLY = (TOTAL_SUPPLY / 10);
    uint constant TAX_RATE = 2;

    address public treasuryAddress;
    bool public taxEnabled;

    // constructor(address _treasuryAddress) ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
    //     treasuryAddress = _treasuryAddress;
    //     mint(_treasuryAddress, INITIAL_SUPPLY);
    // }

    function initialize(address _treasuryAddress) public initializer {
        __ERC20_init(TOKEN_NAME, TOKEN_SYMBOL);
        __Ownable_init();
        treasuryAddress = _treasuryAddress;
        super._mint(_treasuryAddress, INITIAL_SUPPLY);
    }

    function mint(address _account, uint _amount) external {
        require((totalSupply() + _amount) <= TOTAL_SUPPLY);
        super._mint(_account, _amount);
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0));
        treasuryAddress = _treasuryAddress;
    }

    function _transfer(address _from, address _to, uint256 value) internal override {
        uint tax = calculateTax(value);
        if (taxEnabled) {
            super._transfer(_from, treasuryAddress, tax);
        }
        super._transfer(_from, _to, taxEnabled ? value - tax : value);
    }

    function calculateTax(uint _amount) private pure returns(uint) {
        return TAX_RATE * _amount / 100;
    }

    function toggleTax() external onlyOwner {
        taxEnabled = !taxEnabled;
        if (taxEnabled) {
            emit TomatoIcoTaxEnabled();
        } else {
            emit TomatoIcoTaxDisabled();
        }
    }

}
