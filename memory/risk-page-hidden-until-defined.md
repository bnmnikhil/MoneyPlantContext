---
name: risk-page-hidden-until-defined
description: "10 Oct 2026: the Risk page is hidden from the app because what it should show is not settled; its API stays because positions' margin column reads it"
metadata:
  type: decision
---

**Decided 10 Oct 2026 by the owner:** "we have not clearly finalised what exactly risk
should show", so `/app/risk` and its nav item are taken out of the build until the page is
defined. It is a pending feature in `NEXT-STEPS.md` (owner idea 4), not a deleted one.

**Hidden rather than fixed.** The alternative was to repair what it shows first (A1, the
frozen `position_snapshot`; the empty decay series), but fixing the numbers of a page whose
purpose is undecided spends effort on figures that may not survive the redesign. A1 drops out
of the working queue with it.

**What stays:** `/api/risk/summary` and the `risk/` package. The positions table's margin
column reads that endpoint ([[positions-margin-comes-from-risk]]), so removing the backend
would break a live page.

**Also decided the same day:** Google's consent-screen test-user limit (L5) does not apply to
GoldenBook's application, per the owner, so it is not a sign-in blocker and left the queue.
