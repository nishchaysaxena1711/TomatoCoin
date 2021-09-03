Looks good!

At a high-level, I think you're anticipating an ERC-20 (like WETH) instead of actual ether. This is nice because it allows simplifying the back-end code, but you'll need to indicate or facilitate this on the front-end. There's also no method to estimate the exchange rate, which would create an UX challenge.

## Initializing the liquidity pool does not check if the appropriate amount of tokens are actually transferred
*Severity: High*

When `_totalSupply == 0` in the `provideLiquidityToPool()` function, there is no guarantee that the appropriate amount of tokens (as specificied in the constants) were actually transferred to the pool.

## Incorrect checks for sufficient liquidity
*Severity: High*

Lines 125 and 153 check whether the amount of tomato and ether being swapped into the pool is less than the current balance of that asset in the pool, but I believe it should be possible to swap a greater amount of a token into a pool than is already there. Appropriate checks for sufficient liquidity already occur at lines 136 and 163.

## Improper denomination of Tomato Coins
*Severity: High*

Tomato Coin is an ERC-20 using the default `decimals()` value of 18 (equivalent to ether), so `uint constant INITIAL_TOMATO_COINS = 150000;` could be updated to `uint constant INITIAL_TOMATO_COINS = 150000 ether;` or `uint constant INITIAL_TOMATO_COINS = 150000 * 10 ** 18;`

## There is no check ensuring liquidity providers transfer ether and tomato coin of equal value.
*Severity: Medium*

Because of `Math.min` on line 91, you're potentially short-changing the LPs, as they'll receive the smaller of the two values they'd be entitled to.

## Code does not consistently rely on the synced local balances.
*Severity: Medium*

At lines 109 and 114, the token balance according to the ERC20 contract is used rather than the internal state. It would be possible to inflate this, though it's unclear to me if this actually poses a risk. Instead, you might call `sync` at the top of the function and rely on `tomatoBalance` and `etherBalance`, respectively.

## Use interfaces for types
*Severity: Code Quality*

Instead of storing addresses, you can declare the addresses as the interface type. For example, `address tomatoAddress;` becomes `IERC20 tomatoCoin` and `IERC20(tomatoAddress).balanceOf` becomes `tomatoCoin.balanceOf`. It looks like you've done this as suggested with `LPToken`, so you don't need to persist `lpTokenAddress` in a seperate variable, and `LPtoken` can be used instead at line 101.

## Unnecessary duplicate code
*Severity: Code Quality*

Because you're anticipating WETH, it should be possible to 'DRY' up the code by consolidating the logic between the two swap functions into one.
