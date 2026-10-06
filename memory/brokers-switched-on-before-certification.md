---
name: brokers-switched-on-before-certification
description: Upstox and Dhan were enabled for all production users on 6 Oct 2026, before any live-account certification; what that means and how to reverse it
metadata:
  type: project
---

On **6 Oct 2026, 20:58 IST** the owner switched Upstox and Dhan on for every production user
(`GB_ROLLOUT_UPSTOX=available`, `GB_ROLLOUT_DHAN=available`), straight after the dark deploy, skipping the
Phase 2 gates in `RELEASE-ADAPTERS-PLAN.md`.

**Why it matters.** Neither adapter has met a live account. Every field mapping comes from the published reference.
The facts the documentation does not settle are mapped with a stated assumption and a test that names it:
Upstox `average_price` as the real entry and its three holdings quantities as disjoint; Dhan `costPrice`, `totalQty`
and `collateralQty`; Dhan's holdings showing zeros for a user without the paid Data API (Rs 499 plus tax a month).
Wrong assumptions would put wrong figures in front of a user.

**Why it was acceptable to the owner:** the user base is small (3 users on 6 Oct), both brokers were tested end to end
against the simulator on staging, and FOUND-06 makes the flip a one-line, reversible change. The owner made the call
knowing the gates were open; do not relitigate it, close the gates.

**How to apply.** The top open item is live certification, on the laptop in `GB_ENVIRONMENT=local` with dev auth and a
`localhost` redirect (no production exposure), by the owner or a friend. A mapper or test that turns out wrong is
fixed and shipped to production. **To switch a broker off:** remove its `GB_ROLLOUT_*` line from
`/etc/goldenbook/goldenbook.env` and restart; stored sessions stay saved and return when it is back on.

Related: [[browser-redirect-brokers-first]], [[new-brokers-require-no-static-ip]].
