---
name: step-4-landed-as-one-commit
description: "SPEC.md planned 4a–4d as independently mergeable sub-steps; 4b, 4c, 4d and the dashboard rework landed together as a single commit with four acceptance shortfalls open"
metadata:
  type: state
---

`SPEC.md` planned four independently mergeable sub-steps — **4a foundations →
4b InstrumentKey → 4c snapshots and the freshness contract → 4d risk module.**
4a landed as three commits. **4b, 4c, 4d and the dashboard rework then landed
together as one commit, `risk analysis`** (39 files backend, 12 frontend) — the
exact un-splittable commit the plan was written to prevent.

It is still on an unmerged branch, so a rebase-split before merging remains
possible, but it is no longer free.

**Four shortfalls against the sub-steps' own acceptance criteria, all verified in
the code as of 11 Aug 2026:**

1. **Snapshot-first reads are not wired.** `PositionsController` still calls
   `brokers.allPositions()`; `SnapshotService`'s only consumer is `RiskService`,
   and the portfolio endpoints always report `Freshness.LIVE`. D10 and ADR 0016
   are unmet.
2. **Nothing migrates `raw_capture` into the typed tables** — which was the
   entire justification for shipping dumb capture early. `holding_snapshot` and
   `margin_snapshot` have **zero rows and no write path**, and the one live
   fallback that writes `position_snapshot` stores `raw = "{}"`, contradicting
   4c's "reconstructible from `raw`".
3. **ADR 0012 leaks transitively.** ArchUnit A2 checks only *direct* dependencies
   of `..risk..`, so it passes — but `RiskService` → `SnapshotService` →
   `BrokerService` fires a live broker call inside a risk request. Widening A2 to
   transitive reach belongs with whatever lands 4c.
4. **Two of D9's four risk features are stubs.** The decay series returns
   `List.of()`, and margin & capital utilisation is absent from
   `RiskSummaryReport` entirely. Exposure and expiry bucketing are real and
   unit-tested.

**Also shallower than its acceptance claims:** 4b's `InstrumentKey` is referenced
only inside `instrument/` — see [[app-owns-its-symbols]].

**Knowingly deferred:** D11 (generated TS types, CI) entirely — neither repo has
CI, which is also what ADR 0021 and frontend 0022 are waiting on.
