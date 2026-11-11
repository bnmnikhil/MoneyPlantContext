# GoldenBook — business plan and market research

**Prepared 11 Nov 2026 (Claude, from the repo trackers and a web survey the same day).** A first draft for the
owner to correct. Market figures are from public sources listed at the end; most pricing figures come from
third-party pages and must be re-checked on the vendors' own sites. Revenue figures are scenarios, not forecasts.
Nothing here is legal advice.

## 1. The verdict in five lines

1. The problem is real but the market is **narrow**: the buyer is the serious, multi-leg, multi-account F&O
   trader, perhaps 1–2% of an active base of 87.5 lakh that is itself shrinking.
2. Nobody found in this survey sells exactly GoldenBook's product (read-only, multi-broker F&O book with payoff
   on real positions). The nearest neighbours are single-broker analytics (Sensibull, Opstra) and multi-account
   *execution* terminals (Cirrus, FNOTrader), which already show combined positions.
3. The biggest obstacle is not competition. It is **onboarding friction and broker terms**: each user creates a
   developer app per broker, logs in daily, and Zerodha's staff call Kite Connect "personal use only".
4. As a direct-to-trader subscription it is a plausible **small solo business** (₹2–10 lakh a year at a few
   hundred paying users), not a venture-scale one. The larger opportunity is **B2B: analytics for brokers that
   lack them**, which is how Sensibull reached scale and which removes the three obstacles at once.
5. Nothing is validated yet: production holds only the owner's data. The next rupee of effort should buy
   evidence (10 external traders, 5 returning), not features.

## 2. What GoldenBook is today

**Product.** A read-only web app (`goldenbook.in`, live since 3 Oct 2026) that pulls positions, holdings and
margins from a trader's broker accounts into one book, draws payoff charts for what they actually hold
(expiry curve, a projected "today" curve, a target-date slider, multi-expiry valued at the first expiry) and
lets them model an adjustment in a Strategy Builder before trading at their broker. It never places orders.

**Assets built.**
- Five broker adapters: Zerodha Kite, Alice Blue, Paytm Money (all verified on live books), Upstox and Dhan
  (live but uncertified). Together about 23% of NSE's 4.67 crore active-client records; Zerodha is most of it.
- A bottom-up SPAN + exposure margin engine calibrated against real Zerodha bills (within about 9% on the
  account total; 0.60× on Alice Blue, uncalibrated).
- Live option chain for 181 underlyings (Alice Blue), streamed prices (Paytm socket), Black-Scholes projection.
- A broker simulator and staging environment, ~694 backend and ~155 frontend tests, encrypted credential and
  session storage, per-user isolation by design, a documented regulatory position.
- Running cost today: close to zero (OCI always-free VM, Postgres on the same host).

**Not yet there.** No external users. Stage A of the launch queue is mostly open (failure states, cross-user
isolation test, monitoring, erasure, terms acceptance); backups are deferred; Groww (rank 1) is on hold and
Angel One (rank 2) is not integrated; the Risk page is hidden; Research is a plan.

**Stated ambition.** The repo records "analysis is the product" (technical, fundamental, decay, risk/reward,
AI commentary) and "a real product for a limited number of users on minimal infrastructure cost".

## 3. Market research

### 3.1 Size and direction

| Fact | Figure | Source |
|---|---|---|
| Active individual equity-F&O traders, FY26 | **87.5 lakh**, down 18% from 106.2 lakh in FY25 | SEBI FY25–FY26 study (Aug 2026), via Angel One, Finnovate |
| New entrants, FY26 | 20.8 lakh, down ~40% | same |
| Share losing money after costs, FY26 | 87.7% (FY25: 90.9%) | same |
| Aggregate individual net loss, FY26 | ₹91,685 crore; average ~₹1.17 lakh per trader | same |
| Transaction costs paid by individuals, FY26 | ~₹25,000 crore (brokerage ~44%) | same |
| Options-only traders | 93.4% | same |
| Index-option turnover within 7 days of expiry | 97%; on expiry day 59% | same |
| Equity portfolio below ₹1 lakh | 78% of traders | same |
| Declared income below ₹5 lakh | about three-fourths (of those with data) | same |
| Volume concentration | "60–70% of F&O volumes come from just 1–2% of traders" | Nithin Kamath, Apr 2026 |
| NSE active clients, Oct 2026 | 4.67 crore records; Groww 29.4%, Angel One 15.0%, Zerodha 14.5%, Upstox ~18.4 lakh | NSE data via Business Standard, YourStory |

**Reading.** The headline number flatters the opportunity. Most of the 87.5 lakh are small, young, options-only
traders buying or selling near expiry with little capital. They do not hold multi-leg positions for days across
two brokers, and they are not buyers of a review tool. The regulator is actively shrinking this group (larger
lot sizes, one weekly expiry per exchange, upfront premium, higher STT, expiry-day margins) and the trend is
down for two years running.

GoldenBook's buyer is in the other tail: the 1–2% who produce most of the volume, hold structures (spreads,
condors, covered positions against pledged holdings), and often run more than one account (own, spouse, HUF,
or a second broker for collateral, margin or API reasons).

### 3.2 A sizing, with its assumptions shown

| Layer | Estimate | Basis |
|---|---|---|
| Active individual F&O traders | 87.5 lakh | SEBI FY26 |
| Serious traders (hold multi-leg positions, meaningful capital) | 0.9–1.75 lakh | Kamath's 1–2% |
| …of whom run two or more broker accounts | **20,000–70,000** | **Assumption: 20–40%. No public data found.** |
| …reachable with today's five brokers and the API-app setup | 5,000–20,000 | Assumption: a quarter to a third |
| Paying, at 3–10% of reachable | **150–2,000** | Typical freemium conversion range |

The multi-broker share is the number the whole plan rests on, and it is a guess. The 14-day first-user campaign
in `MARKETING.md` is the cheapest way to replace it with evidence.

### 3.3 Competitors and price anchors

| Product | What it is | Multi-broker F&O book? | Price (re-check) |
|---|---|---|---|
| **Sensibull** | Options analytics, strategy builder, payoff; SEBI-registered RA; claims 2M+ users, 50k+ daily | No: one broker login at a time | Free for Zerodha users; Pro ~₹800/month elsewhere |
| **Opstra (Definedge)** | Options analytics, builder, backtesting | No | ₹799–1,300/month + GST |
| **Quantsapp** | Options analytics, mobile-first | No | ~₹4,000/month (PRO) |
| **AlgoTest** | Backtesting and execution, 40+ brokers | Multi-broker for execution | From ₹499/month, credits |
| **Tradetron** | Strategy automation | Multi-broker for execution | ~₹300–1,500+/month |
| **Cirrus, FNOTrader, Stocksdeveloper** | Multi-account / copy-trading terminals; "family" groups, combined MTM, payoff | **Yes, as a by-product of order placement** | Not verified |
| **OpenBull** | Open-source, self-hosted options platform, multi-broker | Per account | Free |
| **INDmoney, Dhan tracker, MProfit** | Holdings and net-worth trackers across brokers | Holdings only; no F&O | Free / low |
| **Broker apps** | Each improving its own payoff and basket tools | Own accounts only | Free |

**What this says.**
- The gap is genuine: read-only, cross-broker, position-first review with honest payoff and margin is not what
  anyone leads with. Analytics tools start from a strategy idea; GoldenBook starts from the book you hold.
- The closest substitutes are the multi-account execution terminals. Their users are exactly the multi-account
  traders, and they already see combined positions there. GoldenBook's answer is "read-only, so no static IP,
  no algo registration, no order risk", plus better payoff and margin.
- Price ceiling: Sensibull is free for Zerodha's clients, so a Zerodha-heavy audience anchors at ₹0 for payoff
  charts. The paid value has to be the cross-account view and what follows from it. A realistic band is
  **₹299–499 a month**, below Opstra and Sensibull Pro.
- Sensibull's scale came through **broker partnerships** (the broker pays or bundles), not consumer
  subscriptions sold one at a time.

### 3.4 Regulation that shapes the business

| Rule | Effect on GoldenBook |
|---|---|
| SEBI retail-algo framework (static IP, algo registration) | Binds order placement only. Read-only is the moat against the execution terminals, and the reason never to add orders casually. |
| SEBI Research Analyst Regulations | Showing facts and user-defined filters is the defensible end; ranked trade ideas and recommendation-like AI text are exposed. Sensibull is a registered RA. Individual registration fees are small (₹2,000 + ₹3,000, plus a RAASB deposit and NISM qualification), so registering is feasible if Research needs it. |
| Broker API terms | Zerodha staff: Kite Connect is "personal use only", ask compliance for multi-user. Unanswered at all three original brokers (L1). The risk lands on the user's API app. |
| Market-data redistribution | The shared admin feed is an accepted risk to ~50 users. Past that, a licensed data vendor is a hard cost. |
| DPDP Rules 2025 | Enforceable 13 May 2027: notice, consent, breach reporting, erasure. |
| SEBI's F&O curbs | Shrink the casual base; the serious tail is less affected and gains more from margin and payoff tools. |

## 4. Positioning

**"Your F&O book across brokers. One place to review it."** (as in `MARKETING.md`)

- **Who:** self-directed NSE F&O traders with two or more accounts who hold multi-leg positions overnight.
- **Why now:** higher margins and fewer expiries push serious traders toward hedged structures and
  collateral-funded books, where knowing the real payoff and margin per account matters more.
- **Why GoldenBook:** read-only (safe to connect), honest numbers (dashes instead of invented zeros, marked
  partial totals, estimate shown beside the broker's real bill), positions first.
- **What it must not claim:** signals, returns, advice, cross-account margin benefit.

## 5. Business model

### 5.1 Three ways to make money

| Route | How | For | Against |
|---|---|---|---|
| **A. Subscription to traders** | Free: one broker, positions, holdings, expiry payoff. Pro (₹299–499/month or ~₹3,000/year): multiple accounts, projected payoff, Builder, alerts, later Research | Fits what is built; no partner needed | Onboarding friction caps the funnel; terms risk; small ceiling |
| **B. Licensed to brokers** | White-label or embedded positions, payoff, margin and builder for brokers whose own tools are weak (the project began because Alice Blue and Paytm Money lack decent position views) | Broker supplies auth, market data and users; no per-user API app; terms problem disappears; one contract can exceed hundreds of subscribers | Long sales cycles; needs a company, references and support capacity; a solo founder is a dependency risk for the buyer |
| **C. Research / insights tier** | Stock pages, screener, book-linked insights, AI summaries on top of A | The owner's stated core; differentiates on "your exposure" | Needs licensed or self-built data, likely RA registration, and competes with free Screener.in / Tickertape |

**Recommendation.** Run A to earn proof, and open B conversations as soon as there are ten external users to
point to. The broker emails already planned under L1 are the natural first B conversation: ask about a
partner route, not only permission. Treat C as a retention feature for A, started only after A shows people
return.

### 5.2 Scenarios (not forecasts)

Assumes Pro at ₹399/month, 2% payment-gateway cost, 18% GST collected on top.

| | Cautious | Base | Stretch |
|---|---|---|---|
| Registered users | 500 | 3,000 | 15,000 |
| Paying users | 40 | 250 | 1,200 |
| Revenue per month | ₹16,000 | ₹1.0 lakh | ₹4.8 lakh |
| Revenue per year | ₹1.9 lakh | ₹12 lakh | ₹57 lakh |

One broker licence under route B at even ₹1–2 lakh a month would equal the base case on its own. That figure
is illustrative; no broker has been asked.

### 5.3 Costs

| Item | Now | When it starts to cost |
|---|---|---|
| Hosting (OCI always-free), domain | ~₹1,000/year | A paid VM once load or reliability demands it |
| Market data | ₹0 (users' own brokers + admin feed) | **At ~50 users: a licensed vendor feed. Get quotes before pricing Pro; this is the largest unknown cost.** |
| Company, GST, accounting | ₹0 | Before the first rupee is charged |
| Legal opinion (broker terms, RA exposure, privacy) | ₹0 | Before charging, and before Research ships |
| RA registration (if Research goes ahead) | — | Fees ~₹5,000 plus deposit, NISM exams, ongoing compliance |
| Hosted observability, backups, AI calls | ~₹0 on free tiers | Scales with users; cap AI per user |
| The founder's time | the real cost | — |

Break-even on cash costs is low (tens of paying users), provided the data feed is affordable. The plan fails
on time and attention, not on rupees.

## 6. Go-to-market

1. **Founder-led, zero spend** (already drafted in `MARKETING.md`): five personal invitations, three observed
   onboarding sessions, one founder post, one community post. Target: 10 activated, 5 returning.
2. **Where the buyers are:** TradingQnA and the Kite forum, broker community forums (Dhan, Alice Blue, Upstox),
   options-selling groups on Telegram and X, people already using broker APIs (setup is not new to them).
3. **Content that sells the product honestly:** "what my book looked like across three brokers", margin
   estimate versus the broker's bill, a payoff before and after an adjustment, all on simulated data.
4. **Reduce friction before widening reach:** a two-minute setup video per broker; Kite and Upstox first
   (free, browser redirect); say the daily login plainly.
5. **Partner track (route B):** a one-page description and a staging demo on the simulator for brokers.

## 7. Roadmap with gates

| Phase | When | Work | Gate to pass |
|---|---|---|---|
| **0. Safe to show** | Nov–Dec 2026 | Finish Stage A (N13, HOLD-PRICE, N7, N8, N9, L4, E3), backups, the monitoring floor | A stranger sees only correct, own data; outages alert |
| **1. Proof** | Jan–Feb 2027 | The 14-day campaign; friends certify Upstox and Dhan; broker emails (permission and partner route) | **10 activated, 5 returning on another day.** If setup blocks most, fix onboarding before anything else |
| **2. Fifty users** | Mar–Jun 2027 | Fix what proof showed; alerts (margin pressure, expiry); calibrate Alice Blue margin; DPDP readiness by 13 May | 50 weekly-active; at least 10 say they would pay; written answer from Zerodha |
| **3. Charge** | Q3 2027 | Company and GST; licensed data feed; payments; Pro tier | 25 paying in the first two months |
| **4. Deepen** | Q4 2027 on | Research section and RA registration if retention justifies it; or a broker pilot if route B opened | Decided on phase 3's numbers |

## 8. Risks

| Risk | Likelihood | Consequence | Response |
|---|---|---|---|
| Too few multi-broker traders care enough | Medium-high | No business in route A | Phase 1 answers this for almost no cost |
| API-app setup and daily login stop most sign-ups | High | Funnel collapses | Observed onboarding, setup guides, API-savvy users first; route B removes it |
| Zerodha objects to hosted multi-user use | Medium | Lose the broker most users have | Ask in writing; browser-side checksum design in reserve; allowlist fallback |
| Market-data terms or cost | Medium | Builder and spot unusable for Kite-only users | Vendor quotes before pricing; admin feed capped at ~50 users |
| Wrong numbers on a real book | Medium | Trust lost with exactly the users who matter | Certification with friends' accounts; dashes over guesses; estimate beside the bill |
| A security incident with stored broker secrets and sessions | Low, severe | Ends the product | Isolation test (N8), backups, key off the VM, monitoring; consider not storing secrets server-side |
| Sensibull or a broker ships multi-account views | Medium | Differentiator narrows | Speed with the niche; route B makes them a customer rather than a rival |
| Regulation shrinks retail F&O further | Medium | Smaller base | The serious tail is the least affected |
| Solo founder, 8 GB laptop, a career switch as first priority | High | Slow progress, stalled support | Keep scope to the four launch features until phase 2's gate |

## 9. When to stop or change course

- Fewer than 3 of 10 invited traders finish setup even with help: the API-app model is the problem. Move to
  route B or stop selling to consumers.
- Activated users do not return within two weeks: the review workflow is not a habit. Interview, then try
  alerts; if still flat, keep GoldenBook as a personal tool and portfolio piece.
- No one of 50 active users will pay ₹299: stay free, minimise cost, and use the product as the reference for
  route B or for the career switch.

## 10. Open questions for the owner

1. Is the goal income, a company, or a strong portfolio piece for the career switch? The plan differs for each.
2. How many hours a week, for how long, before a gate must be passed?
3. Would you approach brokers as a vendor (route B), and may the L1 emails be reworded to ask?
4. Budget for a data feed and a legal opinion, if phase 2's gate is passed.
5. Who are the first five traders to invite?

## Sources

Market: [Angel One on SEBI's FY26 study](https://www.angelone.in/news/market-updates/active-derivatives-trader-base-drops-to-87-5-lakh-in-fy26-sebi-study) ·
[Finnovate summary of the SEBI FY25–FY26 study](https://www.finnovate.in/learn/blog/sebi-fno-trader-losses-fy26-individual-derivatives) ·
[Business Standard on the FY25 study](https://www.business-standard.com/markets/news/net-losses-of-traders-in-fo-widens-in-fy25-sebi-study-125070701221_1.html) ·
[Kamath on volume concentration](https://www.businesstoday.in/amp/markets/stocks/story/zerodhas-nithin-kamath-says-60-70-of-fo-volumes-come-from-just-1-2-traders-526999-2026-04-23) ·
[Angel One overtakes Zerodha, Oct 2026](https://www.business-standard.com/amp/companies/news/angel-one-overtakes-zerodha-to-become-2nd-largest-broker-by-active-clients-126110601754_1.html) ·
[YourStory, same](https://yourstory.com/2026/11/angel-one-becomes-indias-second-largest-broker-by-active-clients) ·
[SEBI F&O rule changes (Alice Blue blog)](https://aliceblueonline.com/blog/sebi-new-fo-rules-2024-to-2026)

Competitors and prices: [Sensibull](https://sensibull.com/) ·
[Sensibull charges (5paisa)](https://forum.5paisa.com/portal/en/kb/articles/what-are-the-subscription-and-brokerage-charges-for-sensibull) ·
[options analytics tools compared](https://onetradejournal.com/platforms/options-analytics-tools-compared) ·
[Opstra review](https://www.strike.money/reviews/definedge-opstra) ·
[AlgoTest on software prices](https://algotest.in/blog/algo-trading-software-price/) ·
[Cirrus](https://cirrus.trade/) · [FNOTrader](https://www.fnotrader.com/options) ·
[Stocksdeveloper](https://stocksdeveloper.in/) · [OpenBull](https://github.com/marketcalls/openbull) ·
[INDmoney tracker](https://www.indmoney.com/features/stocks-shares-portfolio-tracker) ·
[Dhan cross-broker holdings](https://community.dhan.co/t/now-live-track-your-portfolio-holdings-stocks-across-all-stock-brokers-on-dhan/17742)

Regulation: [NISM, becoming a registered RA](https://new.nism.ac.in/prerequisites-for-becoming-a-sebi-registered-research-analyst) ·
[SEBI RA FAQs clarifications](https://lakshmisri.com/insights/articles/key-clarifications-under-the-sebi-issued-faqs-2025) ·
in-repo: `research/BROKER-API-TERMS-MULTI-USER.md`, `research/REGULATORY-API-STATIC-IP.md`,
`research/BROKER-LAUNCH-SHORTLIST.md`, `memory/shared-market-data-fallback.md`.
