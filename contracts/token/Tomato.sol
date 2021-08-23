//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Tomato is Initializable, ERC20Upgradeable, OwnableUpgradeable {

    // events
    event TomatoSalePaused();
    event TomatoSaleResumed();
    event TomatoSaleTaxEnabled();
    event TomatoSaleTaxDisabled();

    // enums
    enum PHASE {
        SEED,
        GENERAL,
        OPEN
    }

    // constants
    string constant TOKEN_NAME = "Tomato";
    string constant TOKEN_SYMBOL = "TMT";
    uint constant TOTAL_SUPPLY = 500000;
    uint constant INITIAL_SUPPLY = (TOTAL_SUPPLY / 10);
    uint constant EXCHANGE_RATE = 5;
    uint constant TAX_RATE = (2 / 100) * 10 ** 18;
    address private tomatoSaleAddress;
    address private treasuryAddress;
    bool public taxEnabled;
    bool public fundRaisingEnabled;

    // variables
    PHASE public phase;
    address public admin;

    modifier afterOpenPhase {
        require(PHASE.OPEN == phase);
        _;
    }

    modifier onlyTomatoSale {
        require(msg.sender == tomatoSaleAddress);
        _;
    }

    // constructor(address _treasuryAddress) ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
    //     admin = msg.sender;
    //     treasuryAddress = _treasuryAddress;
    //     mint(_treasuryAddress, INITIAL_SUPPLY);
    // }

    function initialize(address _treasuryAddress) public initializer {
      __ERC20_init(TOKEN_NAME, TOKEN_SYMBOL);
      __Ownable_init();
      admin = msg.sender;
      treasuryAddress = _treasuryAddress;
      mint(_treasuryAddress, INITIAL_SUPPLY);
    }

    function mint(address _account, uint _amount) internal onlyTomatoSale {
        require((totalSupply() + _amount) <= TOTAL_SUPPLY);
        super._mint(_account, _amount);
    }

    function setTreauryAddress(address _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0));
        treasuryAddress = _treasuryAddress;
    }

    function setTomatoSaleAddress(address _tomatoSaleAddress) external onlyOwner {
        require(_tomatoSaleAddress != address(0));
        tomatoSaleAddress = _tomatoSaleAddress;
    }

    function transferCoins(address _from, address _to, uint256 value) internal onlyTomatoSale {
        uint tax = calculateTax(value);
        if (taxEnabled) {
            super._transfer(_from, treasuryAddress, tax);
        }
        super._transfer(_from, _to, taxEnabled ? value - tax : value);
    }

    function calculateTax(uint _amount) private pure returns(uint) {
        return TAX_RATE * _amount;
    }

}
