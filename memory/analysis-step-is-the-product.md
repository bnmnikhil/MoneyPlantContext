---
name: analysis-step-is-the-product
description: "Step 8 (analysis) is the core of the product, not a late nice-to-have; everything shipped so far is scaffolding, and it is blocked on market data"
metadata:
  type: state
---

**Step 8 — analysis** (technical, fundamental, premium decay, risk/reward, LLM
commentary) is **the core of the product.** Multi-broker aggregation and payoff
graphs are the visible value today, but they are not the thing being built
toward.

**Why this needs recording.** Step 8 sits last on the roadmap and is marked
blocked, which invites reading it as someday-maybe. It is not. It is blocked on
a genuine dependency, and unblocking that dependency is worth more than
finishing several steps above it.

**What blocks it, precisely.** Market data the app does not have: technical needs
history, premium decay needs option prices and IV over time, risk/reward needs
live premiums, and LLM analysis needs something factual underneath. Spot is
solved (Paytm, free, verified). **Per-strike option premiums are not.**

**The open lead.** Alice Blue's option chain — `POST
/obrest/optionChain/getOptionChain` — appears to return per-strike `ltp`, `oi`
and `pdc` at no cost beyond the account. It does **not** return spot directly;
candidates are put-call parity near ATM (`spot ≈ strike + CE_ltp − PE_ltp`) from
the same payload, or the Historical Data endpoint. **Unverified against a live
token.** Verify it the next time a broker is connected — those windows are rare
and the check is cheap.

**Two caveats before treating Step 8 as unblocked:** confirm whether broker terms
permit using one broker's feed to price another's positions; and note that
offering analysis or recommendations may separately engage SEBI RA/IA rules.

**Do not** build analysis features on data not yet confirmed to exist.
