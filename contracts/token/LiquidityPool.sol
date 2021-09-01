//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LPToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {

    event LPMint(address to, uint amount);
    event LPBurn(address from, uint amount);

    string constant LP_OKEN_NAME = "TMT_ETH_TOKEN";
    string constant LP_TOKEN_SYMBOL = "TET";
    address tomatoLPAddress;

    modifier onlyTomatoLP {
        require(msg.sender == tomatoLPAddress, 'Unauthorized user');
        _;
    }

    function initialize(address _tomatoLPAddress) public initializer {
        __ERC20_init(LP_OKEN_NAME, LP_TOKEN_SYMBOL);
        __Ownable_init();
        tomatoLPAddress = _tomatoLPAddress;
    }

    function setTomatoLPAddress(address _tomatoLPAddress) external onlyOwner {
        require(_tomatoLPAddress != address(0));
        tomatoLPAddress = _tomatoLPAddress;
    }

    function mint(address to, uint amount) external onlyTomatoLP {
        super._mint(to, amount);
        emit LPMint(to, amount);
    }

    function burn(address from, uint amount) external onlyTomatoLP {
        require(balanceOf(from) >= amount, 'user does not have enough LPTokens');
        super._burn(from, amount);
        emit LPBurn(from, amount);
    }

}