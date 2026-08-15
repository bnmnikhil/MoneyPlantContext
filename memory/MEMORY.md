# MoneyPlant — project memory

**What this is.** One file per durable decision or piece of project state, with
the reasoning that produced it. `CLAUDE.md` is the *current-state* snapshot and
deliberately cuts closed items and the "why"; this directory is where that "why"
survives. The two are complementary and must not overlap:

| | `CLAUDE.md` | `memory/` |
|---|---|---|
| Answers | *What is true of the code now?* | *Why did we choose this, and when?* |
| Shape | assertions, verifiable against the working tree | decisions, dated, including what was rejected |
| On change | regenerate the affected section in place | append a new memory; amend an old one only when the decision itself is revisited |

**Scope: the MoneyPlant application only.** Not working preferences, not machine
setup, not anything about the people building it.

**Types.** `decision` — a choice made, with alternatives rejected. `state` — where
something actually stands, including known debt. `reference` — a pointer to an
external source of truth.

**Keeping it current.** Add a memory when a decision is made that a future reader
would otherwise have to reverse-engineer from a diff. Amend one when the decision
is genuinely revisited — do not append a changelog inside a file; git holds that.
Delete one when it turns out to be wrong. Every memory is linked from the index
below.

---

## Decisions

- [No cross-broker merging](no-cross-broker-merging.md) — identical instruments at two brokers stay two legs; spreads only earn margin benefit inside one account.
- [P&L has two columns, always](pnl-has-two-columns.md) — brokers disagree on what "P&L" means, so `PositionDto` fixes both and each gateway fills the half its broker withholds.
- [The app owns its symbols](app-owns-its-symbols.md) — broker symbols live only inside that broker's adapter; the symbol-model doc's middle path was overruled in favour of the full model.
- [Sessions persist, encrypted](sessions-persist-encrypted.md) — driven by Paytm having no refresh token and a password+OTP login every time.
- [Credentials are per user, per registration](credentials-per-user-per-registration.md) — one broker app can authorise several logins, and every user registers their own app.
- [A real product, not a personal tool](real-product-not-personal-tool.md) — a limited number of real users, run safely, on free-tier infrastructure.
- [Per-instrument risk model](per-instrument-risk-model.md) — netted per account; "exposure" split into three honest measures; max loss is standalone and must never be summed.
- [Margin attribution model](margin-attribution-model.md) — margin is non-additive, so it is allocated from the broker's real bill and the convention is always stated; split by each leg's own worst scenario.
- [Snapshot writers migrate the archive](snapshot-writers-migrate-the-archive.md) — margin_snapshot is written from raw_capture, never a live fallback, and its "latest" query cannot copy the positions one.
- [Positions margin comes from risk](positions-margin-comes-from-risk.md) — both the subtotal and the account total read `/api/risk/summary`, never `/api/margins`, or the column stops footing.
- [Premium left is negated market value](premium-left-is-negated-market-value.md) — `-(qty × LTP)` from the *live* rows, additive at every level unlike margin, and never coloured by sign.
- [Bottom-up heuristic margin engine](heuristic-margin-engine.md) — offline SEBI/NSE SPAN + Exposure model with spread offsets for strategy simulation and missing broker bills.
- [Strategy builder architecture](strategy-builder-architecture.md) — visual multi-leg designer on `/app/payoff` with 1-click recipes, live simulation, target price probe, and what-if import.

## State

- [Analysis is the product](analysis-step-is-the-product.md) — Step 8 is the core, blocked on market data; unblocking the feed outranks its roadmap position.
- [Step 4 landed as one commit](step-4-landed-as-one-commit.md) — 4b/4c/4d shipped together against the plan; four acceptance shortfalls remain open.
- [Brokers become user-configured](brokers-become-user-configured.md) — the three-broker assumption is temporary; directional only, priority "very far".

## Reference

- [Free market data options, researched](free-market-data-options-researched.md) — Upstox gives per-strike IV and greeks for ₹0; NSE direct is blocked from the VM and its terms do not cover a product.
