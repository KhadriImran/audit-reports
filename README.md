# Audit Reports

Security reviews of EVM smart contracts by **Imran Khadri** · [SENTRYX](https://sentryxaudit.com)

Our rule: a finding is only reported if we can prove it with a runnable Foundry exploit.

## Client reports

| Date | Protocol | Findings | Report |
|---|---|---|---|
| — | Published here after fixes land and with the client's consent | — | — |

## Practice targets

⚠️ **These are not client engagements.** They are deliberately vulnerable test contracts and our own
learning projects, published to show how we work and what a report looks like.

| # | Target | What it is | Findings | Report |
|---|---|---|---|---|
| 01 | VulnVault | Deliberately vulnerable vault used to benchmark our Verdict engine | 2 Critical · 2 High, each with a passing PoC | [REPORT](practice/01-vulnvault/REPORT.md) |
| 02 | flash-arb-lab | Self-audit of our Balancer V2 flash-loan arbitrage contract + bot | 2 Medium · 5 Low · 6 Info (fixed or acknowledged) | [REPORT](practice/02-flash-arb-lab/REPORT.md) |

## Report structure

Scope and commit · severity with rationale · the defect · how funds are lost · walkthrough ·
runnable PoC · impact · recommended fix. Findings are checked against prior audits and known issues.

## Contact

📩 sentryxaudit@gmail.com · [sentryxaudit.com](https://sentryxaudit.com) · [X](https://x.com/ImranKhadri1904)
