Here's your micro audit report!

https://github.com/nishchaysaxena1711/TomatoCoin

The following is a micro audit of git commit b674c57d902acc49ede0a3b4a557c6b8e9902d8a

## issue-1

**[High]** provideLiquidityToPool() calculates incorrect numbers

In Pool.sol:77, transferFrom() may not give the full \_tomatoAmount if the 2% TMTO tax is active, which will cause the function to mint more LP tokens than it should.

This issue also exists on line 127.


## issue-2

**[Medium]** Initial liquidity may be incorrect

In Pool.sol:87, the first liquidity deposit assumes assets a constant amount is in the pool. This is vulnerable to mistakes; it's better to take the actual value of assets in the pool instead.


## issue-3
**[Medium]** Underflow edge case

In TomatoSale.sol:106, the subtraction can underflow when `callerBalance` is larger than `PHASE_GENERAL_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT`, which is possible if someone contributed over 1000 ETH during the Seed phase. This will cause the contract to be unusable for them during the General phase.


## Nitpicks

- Rename "etherAddress" to "wethAddress" or whichever ERC-20 ether wrapper you expect to use for the pool contract.
