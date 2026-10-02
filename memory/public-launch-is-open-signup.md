---
name: public-launch-is-open-signup
description: The October 2026 public launch means open Google sign-up, not open source; the builder ships, the screener does not, and broker consent gates the date.
metadata:
  type: decision
---

**Decided 2 Oct 2026 (owner).** "Taking GoldenBook public" means **open sign-up**: any
Google account may sign in. It supersedes the P0 framing of 20 Aug ("a small invited group,
not family", see [[real-product-not-personal-tool]]). Open-sourcing the repos was offered
and not chosen.

**Scope at launch.** The Strategy Builder ships, so P0 item A6 is dropped. It now has live
chain premiums, and its two wrong inputs are fixed or being fixed
([[nifty-lot-size-is-hardcoded-and-stale]]). The index-spread **Screener stays hidden**
([[index-spread-screener]]). It *ranks specific trades for the user*, which is the end of
the product most exposed to SEBI's Research Analyst rules. A payoff calculator over legs
the user picked is the defensible end. Comparable Indian platforms (Sensibull, the LTP
Calculator) are themselves registered RAs.

**Why broker consent gates the date, not the code.** Kite Connect's terms (§4(b)) say a
user's API key and secret "are intended to be used only by you", and Zerodha staff say
multi-user access needs compliance approval. Alice Blue's terms are near-identical. Per-user
developer apps ([[credentials-per-user-per-registration]]) avoid *sublicensing*, but not the
credential-use clause. For an invite beta this was grey. For open sign-up it is the case
the clause addresses. Rejected: launching anyway, because the downside (a revoked API app)
lands on users who cannot see the risk. Fallbacks, in order: stay allowlisted; open with
Kite limited to the owner; compute Kite's checksum in the browser so the secret never
reaches the server.

**How to apply.** The schedule and the L-items are in `PUBLIC-LAUNCH.md`. Sources are in
`research/BROKER-API-TERMS-MULTI-USER.md`. Open sign-up must be an **explicit mode**, never
an empty allowlist: `AllowedEmails`' refusal to start on an empty list is a property to
keep.
