# GoldenBook: first-user campaign

Prepared 30 October 2026. Campaign proposal and draft copy; nothing published.

## Positioning

**Your F&O book across brokers. One place to review it.**

GoldenBook brings positions, holdings and margins from connected broker accounts
into one view. Review payoff charts for what you hold and model an adjustment in
the Strategy Builder before placing a trade at your broker. GoldenBook is read-only
and never places orders.

Initial audience hypothesis: self-directed NSE F&O traders who actively manage
two or more broker accounts and currently reconcile their book across tabs or
spreadsheets. Start with people who already use broker APIs; setup is a smaller
obstacle for them. Validate this audience through conversations.

Lead with the multi-account review workflow. Show payoff and adjustment modelling
as the second reason to return. Do not market signals, returns, an advisory service,
cross-account margin offsets, a hidden Risk page or the Screener.

## First experiment

Run a 14-day founder-led campaign starting after production checks below pass.
Proposed target: 10 external traders connect a broker and view their own book;
five return on a different trading day. These are experiment targets, not forecasts.

Start with zero paid media spend. The first question is whether a trader completes
setup and finds a reason to return. Review paid acquisition after this experiment.

| When | Action | Evidence to collect |
|---|---|---|
| Days 1-2 | Prepare a 60-second demo and share the invitation personally with five relevant contacts | Which problem resonates; broker mix; willingness to set up |
| Days 3-5 | Offer setup help, observe three onboarding sessions and fix the biggest documented friction | Where setup stops; time to first useful view |
| Days 6-7 | Publish one founder post on an existing LinkedIn or X account | Qualified replies and completed onboarding |
| Days 8-10 | Share the demo in one relevant trader community where promotion is permitted | Questions, objections and activated users from that community |
| Days 11-14 | Follow up with consenting participants; publish a workflow post using simulated data | Return usage, useful workflows and reasons for leaving |

These channel choices are low-cost test hypotheses, not claims about current
platform reach. Use existing relationships first. Do not mass-message people or
post in groups without checking their rules. Obtain permission before quoting users.

## Ready-to-use copy

### Founder launch post

Trading F&O across more than one broker means reviewing your book across more
than one screen.

I built GoldenBook to bring positions, holdings and margins from connected broker
accounts into one place. You can review the payoff of what you actually hold and
try an adjustment in the Strategy Builder before trading at your broker.

GoldenBook is read-only. It never places an order.

I'm looking for 10 NSE F&O traders who use multiple broker accounts to try it and
tell me where the workflow helps and where it gets in the way.

Setup requires your own broker API app, and broker sessions need reconnecting
each trading day. Some brokers charge for API access.

Take a look: https://goldenbook.in

Which part of reviewing your book across brokers takes the most effort today?

### Short post

Managing F&O across brokers? I built GoldenBook to review connected accounts'
positions, holdings, margins and payoff charts in one place. Read-only; no orders.
Looking for early users and candid feedback. Broker API setup required.
https://goldenbook.in

### Personal invitation draft

Hi [name], you mentioned using [brokers]. I built GoldenBook to review positions,
holdings, margins and payoff charts across connected broker accounts. It is
read-only and never places orders.

Would you be interested in trying it and telling me whether it improves your
daily review? You need your own broker API app; some brokers charge for API access.
I can walk through setup with you, while you keep credentials on your own screen.

Here is the app: https://goldenbook.in

### Follow-up workflow post

Before adjusting an F&O position, I want to see what changes in its payoff.

GoldenBook lets you start from the positions you hold, edit a draft strategy and
compare the payoff. The actual trade still happens at your broker.

[Attach the simulated before-and-after demo.]

Payoff and margin figures are estimates. Mixed-expiry charts are simplified
scenarios, and your broker remains the source of truth for its margin bill.

Explore: https://goldenbook.in

## Demo brief

Use the app with synthetic accounts and label all footage "Simulated accounts
and prices". Existing landing images live in `MoneyPlantFrontend/public/landing/`.
Never show a real person's holdings, API keys, login tokens or account identifiers.

| Seconds | Show | Narration |
|---|---|---|
| 0-10 | Overview with multiple accounts | "Review your F&O book across connected broker accounts." |
| 10-25 | Positions grouped by account and underlying | "See positions, P&L and margins without switching broker screens." |
| 25-40 | Payoff for one account and underlying | "Review the payoff of what you actually hold." |
| 40-52 | Import into Builder; edit one draft leg | "Model an adjustment before trading at your broker." |
| 52-60 | URL and setup note | "GoldenBook is read-only. Bring your own broker API app to get started." |

Keep account-level grouping visible: payoff and margin benefits are not merged
across broker accounts. Verify the demo's quote source; current landing copy says
live Builder premiums need an Alice Blue connection. Do not promise universal
live quotes, tick-by-tick data, instant setup or free broker API access.

## Measurement

Use a private, access-controlled tally or tracker. Do not put participant identities,
account details or credentials in this repository.

Record source, permission to follow up, signup completed, first broker connected,
own positions/holdings viewed, return on a later trading day, and the main obstacle.
Track only aggregate counts here if a later update needs results.

Activation = a non-owner trader connects at least one broker and successfully
views their own positions or holdings. An empty account needs an observed useful
workflow before counting as activated. Retention = an activated trader returns
on a different trading day and reviews their book again.

For public links, optional source tags:

- LinkedIn: `https://goldenbook.in/?utm_source=linkedin&utm_medium=organic_social&utm_campaign=first_users`
- X: `https://goldenbook.in/?utm_source=x&utm_medium=organic_social&utm_campaign=first_users`

These links label traffic only. Attribution is not verified or implemented by
this document; use self-reported source until tracking is confirmed.

After 14 days: if setup blocks most interested traders, improve onboarding before
expanding reach. If activated users do not return, interview them about usefulness
and data confidence. If five return, repeat the best source with a larger cohort.

## Production checks before sending or publishing

- Complete or verify N6/D1 off-VM backups. The owner's existing decision in
  `memory/backups-deferred-until-first-user.md` explicitly triggers this before
  any announcement or marketing. Status is not verified in this session.
- Test Google signup and a broker connection with an external user's account.
  Confirm support and deletion contact details on the live site.
- Verify enabled brokers and their real-account data before making broker-specific
  promises. Existing notes record uncertified Upstox and Dhan mappings; source
  includes Alice Blue, Dhan, Paytm Money, Upstox and Zerodha Kite, which is not
  proof of current production readiness.
- Check any price claims against the actual offer. This campaign deliberately
  makes no subscription-price or lifetime-free claim.
- Check screenshots and walkthrough against the deployed application. The live
  homepage could not be fetched with the web tool during preparation.

## Basis and scope

Prepared from `docs/product/overview.md`, `PUBLIC-LAUNCH.md`, current project memory,
and `MoneyPlantFrontend/src/pages/LandingPage.tsx` plus its supported-broker list.
Some older overview and launch notes disagree with newer source or memory; verify
production for launch claims. No external messages sent, accounts created, posts
published, advertising purchased, code changed or deployment performed.
