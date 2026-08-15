---
name: snapshot-writers-migrate-the-archive
description: "margin_snapshot is written by migrating raw_capture, never by a live fallback, because only the archive carries the vendor payload ADR 0013 promises rows are reconstructible from"
metadata:
  type: decision
---

Decided 15 Aug 2026, giving `margin_snapshot` its first writer.

**`TypedSnapshotRepository.saveMargin` shipped in 4c with no caller anywhere** —
a writer method with no writer. So the table had zero rows, there was no read
path, and under ADR 0012 `risk/` could not legally see margins at all. That is
the D9-vs-0012 contradiction `CLAUDE.md` flags: D9 calls margin utilisation
"ready immediately — `/api/margins`" while 0012 forbids risk from touching
`broker/`, leaving it ready via an empty table. See
[[step-4-landed-as-one-commit]].

**The archive is the only writer, and that is the design.** `SnapshotService`'s
position and holding fallbacks each persist `raw = "{}"`, because
`BrokerService` hands back mapped DTOs and never the vendor bytes — so a row
written there cannot be re-derived from its own payload, exactly what ADR 0013's
raw column exists to prevent. `raw_capture` *does* have the bytes and all three
brokers already had a tested `RawPortfolioParser.margin()`, so migrating costs
almost nothing and keeps the promise. `getMargins` therefore reads snapshots and
falls back live **without writing** — a deliberate asymmetry with the other two.

It matters concretely: Kite's `utilised.span`/`.exposure` and Alice Blue's
`utilizedSpanMargin`/`utilizedExposureMargin` are discarded at the mapper and
survive *only* in raw — and they are what [[margin-attribution-model]] has to be
checked against.

**Bookkeeping is an anti-join, not a watermark or a flag.** Keeps the archive
free of any column belonging to one consumer, and self-corrects: delete a
snapshot row and the next run rebuilds it. Known cost — a payload yielding no
margin is re-read every run — is rare and bounded; if that changes the fix is a
migration-watermark table keyed by target, never a flag on `raw_capture`.

**`findLatestMargins` must not copy the positions query.** `findLatestPositions`
and `findLatestHoldings` filter on `captured_at = (select max(captured_at))`,
safe only because one fan-out stamps every row with one instant. Margin rows are
migrated one archive row at a time, so each connection has its own timestamp.
Measured on real Postgres with three connections archived minutes apart:

- `distinct on (connection_id) ... order by captured_at desc, id desc` → 3 rows, correct
- `captured_at = (select max(captured_at) ...)` → **1 row, silently drops two brokers**

`id desc` is required because `captured_at` defaults to `now()`, which in
Postgres is *transaction* start time, so rows written together tie. The same bug
was caught in `findLatestSpots`. **Whoever backfills positions or holdings next
must change those two queries too.**
