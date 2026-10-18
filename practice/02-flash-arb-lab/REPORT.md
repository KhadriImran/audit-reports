> **⚠️ PRACTICE TARGET — self-audit of our own learning project, not a client engagement.**
> Code: [KhadriImran/flash-arb-lab](https://github.com/KhadriImran/flash-arb-lab) (local Arbitrum fork only, never deployed).
> Every fixed finding is covered by a fork test in that repo (11/11 passing).

# FlashArb self-audit (Phase 5)

Scope: `src/FlashArb.sol`, `src/interfaces/IExternal.sol`, bot in `bot/src/`.
Method: manual review + the 11 fork tests in `test/FlashArb.t.sol` (all passing).

## Findings

| ID | Severity | Issue | Fix / status |
|---|---|---|---|
| F-01 | Medium | Anyone can call `Vault.flashLoan(recipient = FlashArb, ...)`. `msg.sender` is then the real Vault, so a vault check alone does not stop it, and the attacker's params run with our contract's funds and approvals. | ✅ Fixed: `_loanActive` flag is only true inside our own `startArbitrage`. Tested: `test_Attack_LoanStartedByStranger`. |
| F-02 | Medium | `receiveFlashLoan` is external, so anyone could call it directly with fake data. | ✅ Fixed: `msg.sender == VAULT` check. Tested: `test_Attack_DirectCallbackCall`. |
| F-03 | Low | `renounceOwnership()` would leave tokens stuck forever with no one able to withdraw. | ✅ Fixed: overridden to revert. Tested: `test_RenounceDisabled`. |
| F-04 | Low | One-step `transferOwnership` with a typo hands the contract to a dead address. | ✅ Fixed: `Ownable2Step` (new owner must accept). |
| F-05 | Low | Callback trusted that the Vault sent the token we asked for. | ✅ Fixed: `tokens.length == 1 && tokens[0] == p.tokenBorrow` check. |
| F-06 | Low | `deadline: block.timestamp` gives no real deadline. A tx stuck in a queue executes whenever it lands. | ⚠️ Acknowledged. `minOut*` and `minProfit` still bound the loss. For mainnet, pass a real deadline in `ArbParams`. |
| F-07 | Low | `minProfit` is measured in tokens and ignores gas, so with `minProfit = 1` a trade can be "profitable" but lose money after gas. | ⚠️ Mitigated in the bot: it sets `minProfit >= estimated gas cost`. |
| F-08 | Info | Fee-on-transfer or rebasing tokens break the balance math. | ⚠️ Acknowledged. The owner chooses tokens; use only plain ERC-20s (WETH, USDC). |
| F-09 | Info | The owner is fully trusted (chooses tokens, pool fee and route). A malicious `tokenMid` could attempt reentrancy. | ✅ Limited: `nonReentrant` on start/withdraw, the Vault's own `flashLoan` is non-reentrant, and the `_loanActive` + Vault checks hold. |
| F-10 | Info | Approvals are exact and reset to 0 after each swap. | ✅ Good practice, already done (`forceApprove`). |
| F-11 | Info (gas) | `_loanActive` uses a storage slot (~20k gas per arb for set/reset). | 💡 Could use transient storage (`tstore`) or `ReentrancyGuardTransient` on Cancun chains. |
| F-12 | Info | DEX/Vault addresses are `constant`. If a DEX migrates, you must redeploy. | Acceptable for this design (and safer than mutable addresses). |
| F-13 | Info (bot) | The loan size comes from a coarse grid (0.05…5 WETH). On the fork the first trade overshot and created a reverse gap. | 💡 Use binary search or the closed-form optimal size for V2/V3 pools. |

## What real mainnet would need

| Topic | Why it matters |
|---|---|
| Speed / latency | Arbitrum has no public mempool. The sequencer orders transactions first-come-first-served, and since 2025 Timeboost lets an auction winner get a time advantage. Pro bots run next to the sequencer feed with sub-millisecond logic. |
| Private / dedicated RPC | Public RPCs are slow and rate-limited. You'd need your own node or a paid low-latency endpoint. |
| MEV competition | Every visible gap is chased by dozens of professional bots. They usually win before a normal bot even sees the block. |
| Real gas model | Arbitrum gas = L2 execution + an L1 data fee. Failed attempts still cost gas. |
| Better routing | Real gaps are tiny (0.0x%) and live across many pools and DEXs, which needs multi-hop routing and precise sizing. |
| Key management | A real hot wallet, ideally separate from your main funds, a hardware wallet as owner, and monitoring. |
| Audit + testing | A professional audit, invariant/fuzz tests, and a kill switch. |

## Honest profitability

- On the fork we made ~0.58 WETH **only because we created a 33% price gap ourselves** with a fake whale.
  Real markets almost never show that.
- The real gap we saw at the fork block was **0.42%**, and the bot correctly said **"no profit"**: fees
  (0.05% + 0.3%) plus price impact on the small (~$89k) Sushi pool ate it all.
- Simple two-DEX arbitrage on a major pair is one of the most competitive games in crypto.
  For a new bot, the realistic expected result is **$0 profit, with small losses from failed transactions.**
