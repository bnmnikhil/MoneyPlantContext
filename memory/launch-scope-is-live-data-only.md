---
name: launch-scope-is-live-data-only
description: "11 Oct 2026: GoldenBook launches with positions, holdings, payoff and the Strategy Builder on live data only; no history is captured, raw_capture is switched off, Risk is hidden, margin is calculated live"
metadata:
  type: decision
---

**Decided 11 Oct 2026 (owner).** At launch GoldenBook does four things: **positions, holdings, payoff graphs and
the Strategy Builder, all on the user's current live data.** Nothing at launch looks at yesterday, so nothing is
stored for it.

**What follows from it:**

- **No market-history capture before launch.** It was designed (one narrow table per contract per moment,
  partitioned by month; NSE end-of-day files first, an intraday watchlist later) and then deferred: history is
  needed only for risk analytics and back-testing, and the end-of-day half can be **backfilled** when that work
  starts. Intraday chain history cannot be backfilled; that loss is accepted. Before relying on NSE files, re-read
  [[free-market-data-options-researched]]: NSE direct was unusable from the OCI VM in Aug 2026.
- **`raw_capture` is switched off** (on-fetch capture and the end-of-day job), and its rows, all the owner's,
  are deleted. It stored every user's whole portfolio every 15 minutes for no launch feature, which with strangers
  is personal financial data to secure, disclose and erase for nothing. L14 (its growth) goes with it. This
  reverses the capture-early rationale of `SPEC.md` 4c and [[snapshot-writers-migrate-the-archive]].
- **Snapshots are out of scope.** Every launch page reads live. The one exception, the positions margin column
  ([[positions-margin-comes-from-risk]]), **must be calculated live**: it moves off `/api/risk/summary`, whose
  positions freeze at a user's first visit (`SnapshotService.getPositions` falls back live only when a user has
  no rows).
- **Risk is hidden now** ([[risk-page-hidden-until-defined]]); N2 is no longer postponed.
- **Backups shrink** to `app_user` and `broker_credential` ([[backups-deferred-until-first-user]]).

**Rejected:** a table per stock for history (hundreds of tables, every migration repeated, cross-stock queries
impossible); capturing "just in case" before a feature needs it.

**How to apply:** do not add a write path that keeps a user's data past the request unless a shipped feature reads
it. Risk, history and back-testing come after launch and decide then what to store. The staged plan is in
`NEXT-10.md`.
