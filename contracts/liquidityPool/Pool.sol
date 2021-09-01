//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import '../token/LiquidityPool.sol';
import "hardhat/console.sol";

contract EthTomatoPool is Initializable, OwnableUpgradeable {

    event LiquidityContribution(address sender, uint tomatoAmount, uint ethAmount, uint lpToken);
    event LiquidityWithdraw(address sender, uint tomatoAmount, uint ethAmount, uint lpToken);

    event SwapTmtToEth(uint tmtAmount, uint ethAmount);
    event SwapEthToTmt(uint ethAmount, uint tmtAmount);

    LPToken lpToken;
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    uint constant INITIAL_TOMATO_COINS = 150000;
    uint constant INITIAL_ETHER = 30000 ether;
    address etherAddress;
    address tomatoAddress;
    address treasuryAddress;
    address lpTokenAddress;
    uint public tomatoBalance;
    uint public etherBalance;

    function initialize(address _treasuryAddress, address _etherAddress) public initializer {
        require(_treasuryAddress != address(0));
        require(_etherAddress != address(0));

        __Ownable_init();
        treasuryAddress = _treasuryAddress;
        etherAddress = _etherAddress;
    }

    function setLPTokenAddress(address _lpTokenAddress) external onlyOwner {
        require(_lpTokenAddress != address(0));
        lpTokenAddress = _lpTokenAddress;
        lpToken = LPToken(_lpTokenAddress);
    }

    function setTomatoTokenAddress(address _tomatoAddress) external onlyOwner {
        require(_tomatoAddress != address(0));
        tomatoAddress = _tomatoAddress;
    }

    function sync() internal {
        tomatoBalance = IERC20(tomatoAddress).balanceOf(address(this));
        etherBalance = IERC20(etherAddress).balanceOf(address(this));
    }

    // Logic to find square root is taken from https://ethereum.stackexchange.com/questions/2910/can-i-square-root-in-solidity/2920
    // Not able to find Math.sqrt in Math.sol (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol).
    // Found uniswap v2 is also using this here: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/libraries/Math.sol#L11
    // Need to check with team if anyone found a good solution for this.
    function calculateSquareRoot(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function provideLiquidityToPool(uint _tomatoAmount, uint _etherAmount) external {
        // Assumption taken for this assignment : tomato amount and ether amount are in equal proportion.
        require(IERC20(tomatoAddress).balanceOf(msg.sender) >= _tomatoAmount, 'sender does not have enough tomato');
        require(IERC20(etherAddress).balanceOf(msg.sender) >= _etherAmount, 'sender does not have enough ether');

        bool isTomatoTransfered = IERC20(tomatoAddress).transferFrom(msg.sender, address(this), _tomatoAmount);
        require(isTomatoTransfered == true, 'contribute: tomato transfer transaction unsuccessful');

        bool isEthTransfered = IERC20(etherAddress).transferFrom(msg.sender, address(this), _etherAmount);
        require(isEthTransfered == true, 'contribute: ether transfer transaction unsuccessful');

        sync();
        uint _totalSupply = lpToken.totalSupply();
        uint liquidity;
        if (_totalSupply == 0) {
            liquidity = calculateSquareRoot(INITIAL_TOMATO_COINS * INITIAL_ETHER) - MINIMUM_LIQUIDITY;
        } else {
            uint tmt = _tomatoAmount * _totalSupply / tomatoBalance;
            uint eth = _etherAmount * _totalSupply / etherBalance;
            liquidity = Math.min(tmt, eth);
        }
        require(liquidity > 0);
        lpToken.mint(msg.sender, liquidity);

        emit LiquidityContribution(msg.sender, _tomatoAmount, _etherAmount, liquidity);
    }

    function withdrawLiquidityFromPool(uint _amount) external {
        require(_amount > 0, 'sender must withdraw amount more than 0');
        require(IERC20(lpTokenAddress).balanceOf(msg.sender) >= _amount, 'sender does not have enough LP tokens');

        uint totalSupply = lpToken.totalSupply();
        uint tmtAmount = tomatoBalance * _amount / totalSupply;
        uint ethAmount = etherBalance * _amount / totalSupply;
        lpToken.burn(msg.sender, _amount);

        require(tmtAmount > 0, 'tomato should be > 0');
        require(IERC20(tomatoAddress).balanceOf(address(this)) >= tmtAmount, 'owner does not have enough tomato');
        bool isTomatoTransfered = IERC20(tomatoAddress).transfer(msg.sender, tmtAmount);
        require(isTomatoTransfered == true, 'withdraw: tomato transfer transaction unsuccessful');

        require(ethAmount > 0, 'ether should be > 0');
        require(IERC20(etherAddress).balanceOf(address(this)) >= ethAmount, 'owner does not have enough ether');
        bool isEthTransfered = IERC20(etherAddress).transfer(msg.sender, ethAmount);
        require(isEthTransfered == true, 'withdraw: ether transfer transaction unsuccessful');
        sync();

        emit LiquidityWithdraw(msg.sender, tmtAmount, ethAmount, _amount);
    }

    function swapTomatoToEth(uint _tomatoAmount) external {
        require(_tomatoAmount > 0, 'tomato swap amount must be > 0');
        require(IERC20(tomatoAddress).balanceOf(msg.sender) >= _tomatoAmount, 'sender does not have enough tomato tokens');
        require(_tomatoAmount < tomatoBalance, 'tomato liquidity is not sufficient');

        bool isTomatoTransfered = IERC20(tomatoAddress).transferFrom(msg.sender, address(this), _tomatoAmount);
        require(isTomatoTransfered == true, 'swapTomatoToEth: tomato transfer transaction unsuccessful');
        
        sync();

        uint k = etherBalance * tomatoBalance;
        uint x = tomatoBalance + _tomatoAmount;
        uint y = k / x;
        uint ethAmt = ethBalance - y;
        require(etherBalance > y);
        uint expAmt = _tomatoAmount * etherBalance / tomatoBalance;

        require(10 * (expAmt - ethAmt) / expAmt < 1, 'swap slippage is more than 10%');

        uint transferAmtAfterFee = ethAmt - (ethAmt / 100); // 1% fee
        require(transferAmtAfterFee > 0);

        bool isEthTransfered = IERC20(etherAddress).transfer(msg.sender, transferAmtAfterFee);
        require(isEthTransfered == true, 'swapTomatoToEth: ether transfer transaction unsuccessful');

        emit SwapTmtToEth(_tomatoAmount, transferAmtAfterFee);
    }

    function swapEthToTomato(uint _etherAmount) external {
        require(_etherAmount > 0, 'ether swap amount must be > 0');
        require(IERC20(etherAddress).balanceOf(msg.sender) >= _etherAmount, 'sender does not have enough ether');
        require(_etherAmount < etherBalance, 'ether liquidity is not sufficient');

        bool isEtherTransfered = IERC20(etherAddress).transferFrom(msg.sender, address(this), _etherAmount);
        require(isEtherTransfered == true, 'swapEthToTomato: ether transfer transaction unsuccessful');
        
        sync();

        uint k = etherBalance * tomatoBalance;
        uint x = etherBalance + _etherAmount;
        uint y = k / x;
        require(tomatoBalance > y);
        uint tmtAmt = tomatoBalance - y;
        uint expAmt = _etherAmount * tomatoBalance / etherBalance;

        require(10 * (expAmt - tmtAmt) / expAmt < 1, 'swap slippage is more than 10%');

        uint transferAmtAfterFee = tmtAmt - (tmtAmt / 100); // 1% fee
        require(transferAmtAfterFee > 0);
        
        bool isTomatoTransfered = IERC20(tomatoAddress).transfer(msg.sender, transferAmtAfterFee);
        require(isTomatoTransfered == true, 'swapEthToTomato: tomato transfer transaction unsuccessful');

        emit SwapEthToTmt(_etherAmount, transferAmtAfterFee);
    }

}
