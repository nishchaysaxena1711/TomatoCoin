https://github.com/nishchaysaxena1711/TomatoCoin

The following is a micro audit of git commit d1bc6f3c980993158c8c657ae2ad12487dc63afb

## General Comments

In TomatoSale.sol:10, the `interface IERC20TomatoCoin` works. If you want extra type safety, you can import `Tomato.sol` and write `Tomato` instead of `IERC20TomatoCoin` on line 37.


## issue-1

**[High]** mint() has no access control

In Tomato.sol:34, the `mint()` function can be called by any account.


## issue-2

**[High]** Mixed unit type comparison

In TomatoSale.sol:120, an ETH value (totalEtherRaised) is compared with a TMTO value (500,000).


## issue-3

**[Medium]** Underflow edge case

In TomatoSale.sol:115, the subtraction can underflow when `callerBalance` is larger than `PHASE_GENERAL_MAX_INDIVIDUAL_CONTRIBUTION_LIMIT`, which is possible if someone contributed over 1000 ETH during the Seed phase. This will cause the contract to be unusable for them during the General phase.


## issue-4

**[Low]** Contributing over limit emits a zero Contribution event

In TomatoSale.sol:105 and :113, the require statements check the current balance instead of the current balance + msg.value. This allows `remainingBalance` to be set to zero, and consequently allows `amount` to be set to zero, eventually producing a Contribution with a zero amount.


## issue-5

**[Code Quality]** Variable misnomer

In TomatoSale.sol:97, `tokenSupply` is a misnomer, as it's being assigned to an ETH value.


## Nitpicks

- Consider combining TomatoSaleResumed and TomatoSalePaused into one event to save on code size.
- Consider combining addAddressToWhitelist and removeAdressFromWhitelist into one function to save on code size.
- Typo in removeAdressFromWhitelist
- Typo in "Reedemption availale in Open Phase"
- Missing word in "You do not enough coins for redemption"