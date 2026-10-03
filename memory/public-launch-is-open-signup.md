---
name: public-launch-is-open-signup
description: Public launch has open sign-up without a user cap; the 3 Oct owner revision expects low initial usage and defers broker outreach and backups.
metadata:
  type: decision
---

**Decided 2 Oct 2026 (owner).** "Taking GoldenBook public" means **open sign-up**: any
Google account may sign in. It supersedes the P0 framing of 20 Aug ("a small invited group,
not family", see [[real-product-not-personal-tool]]). Open-sourcing the repos was offered
and not chosen. **Confirmed 3 Oct 2026:** open sign-up has no user cap or
invitation restriction. The owner expects a small initial cohort; this is an
expectation, not an admission control. L3 owns the explicit open-mode
implementation; local code is on `launch/l3-open-signup`, and live authentication
is still unchanged. See [[google-signup-modes]] for the admission decision.

**Scope at launch.** The Strategy Builder ships, so P0 item A6 is dropped. It now has live
chain premiums, and its two wrong inputs are fixed or being fixed
([[nifty-lot-size-is-hardcoded-and-stale]]). The index-spread **Screener stays hidden**
([[index-spread-screener]]). It *ranks specific trades for the user*, which is the end of
the product most exposed to SEBI's Research Analyst rules. A payoff calculator over legs
the user picked is the defensible end. Comparable Indian platforms (Sensibull, the LTP
Calculator) are themselves registered RAs.

**Current work order, owner revision 3 Oct 2026.** Correct live figures, useful
analysis and everyday onboarding take priority. With only the owner's account
and little irreplaceable retained data, backup automation and restore rehearsal
(D1) move down the queue; revisit as users or retained history grow.

**Broker outreach (L1) is deferred two to three weeks.** Review on 17–24 Oct
2026 using actual sign-ups and active usage, then decide the next outreach step.
Keep the existing email drafts unsent during this interval. This supersedes the
2 Oct decision that written consent gated the launch date. Permission remains
unconfirmed; the research in `research/BROKER-API-TERMS-MULTI-USER.md` is not
changed, and small user numbers are not recorded as evidence of broker approval.

**How to apply.** The schedule and the L-items are in `PUBLIC-LAUNCH.md`. Sources are in
`research/BROKER-API-TERMS-MULTI-USER.md`. Open sign-up must be an **explicit mode**, never
an empty allowlist: `AllowedEmails`' refusal to start on an empty list in **allowlist
mode** is a property to keep. Explicit open and closed modes need no list.
