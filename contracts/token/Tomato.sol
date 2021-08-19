//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tomato is ERC20, Ownable {

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

    constructor(address _treasuryAddress) ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        admin = msg.sender;
        treasuryAddress = _treasuryAddress;
        mint(_treasuryAddress, INITIAL_SUPPLY);
    }

    function mint(address _account, uint _amount) internal onlyTomatoSale {
        require((totalSupply() + _amount) <= TOTAL_SUPPLY);
        _mint(_account, _amount);
    }

    function setTreauryAddress(address _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0));
        treasuryAddress = _treasuryAddress;
    }

    function setTomatoSaleAddress(address _tomatoSaleAddress) external onlyOwner {
        require(_tomatoSaleAddress != address(0));
        tomatoSaleAddress = _tomatoSaleAddress;
    }

}
