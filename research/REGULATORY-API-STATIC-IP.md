# SEBI and broker restrictions on API trading — static IP, API keys, algo status

**Researched 6 Aug 2026 from primary sources.** Regulatory reference, not legal advice. Every clause below is quoted from the circular text, not from a summary; where a fact comes from a broker forum or a vendor blog it is labelled as such.

**The framework has been fully in force since 1 April 2026.** This is not upcoming work to plan for — it is the environment MoneyPlant is already deployed into.

---

## ▶ The short version, for this project

1. **MoneyPlant places no orders.** Verified in the code, not assumed: nothing in `tradestack/src` calls an order endpoint. The one grep hit, `PaytmBrokerGateway.POSITIONS = "/orders/v1/position"`, is a read path. Positions, holdings, margins and payoff are all read-only.
2. **Therefore the static-IP mandate does not currently bind MoneyPlant.** NSE's FAQ is explicit that the client static IP is required "only in case of Tech savvy Investor using API for placing orders", and Zerodha enforces it on order endpoints alone — orderbook, positions and the WebSocket feed stay reachable from any IP.
3. **CLAUDE.md's "static IP (SEBI requirement)" is wrong as stated** for what the app does today. The reserved OCI IP is needed for the DNS A record, the TLS certificate and the broker redirect URIs. Those are operational reasons and they are sufficient — keep the reserved IP, just stop attributing it to SEBI.
4. **The moment MoneyPlant places an order for anyone, three walls appear at once**, and the middle one is close to fatal for the multi-user shape. See "What changes if orders are ever added" below. Worth knowing *now*, because Step 6 (strategy builder) sits one step away from it.
5. **3d's per-user credentials are now backed by a rule, not only by a terms-of-service argument.** SEBI requires access "only through a unique vendor client specific API key and static IP whitelisted by the broker". One shared app key serving several users is the thing the clause exists to forbid.

---

## Primary sources

| Document | Ref | Date |
|---|---|---|
| SEBI, *Safer participation of retail investors in Algorithmic trading* | SEBI/HO/MIRSD/MIRSD-PoD/P/CIR/2025/0000013 | 4 Feb 2025 |
| NSE, *Implementation Standards* (Annexure to the above) | NSE/INVG/67858 | 5 May 2025 |
| NSE, *Detailed Operational Modalities* | NSE/INVG/69255 | 22 Jul 2025 |
| NSE, *Corrigendum — empanelment criteria* | NSE/INVG/70309 | 19 Sep 2025 |
| SEBI, *Extension of timeline* | SEBI/HO/MIRSD/MIRSD-PoD/P/CIR/2025/132 | 30 Sep 2025 |
| NSE, *FAQs — Safer participation of Retail investors in Algorithmic trading* | — | 3 Nov 2025 |

The two NSE documents that matter most are the 5 May implementation standards (the actual rules) and the 3 Nov FAQ (which narrows them in the one way that matters here). The SEBI circular is the shortest and the least operationally specific of the three.

## Timeline — how the dates moved

- **4 Feb 2025** — circular issued, para 7(b): applicable "with effect from August 01, 2025".
- **5 May 2025** — NSE publishes the implementation standards.
- **30 Sep 2025** — SEBI extends, replacing the single date with a glide path:
  - **31 Oct 2025** — each broker applies to register at least one retail algo strategy, plus its API-offered retail algo products.
  - **30 Nov 2025** — registration of those products and strategies completed.
  - **3 Jan 2026** — broker participates in at least one full mock session.
  - **5 Jan 2026** — a broker that missed the above may not onboard *new* retail clients for API-based algo trading.
  - **1 April 2026** — the framework, the implementation standards and the operational modalities apply to **all** stock brokers.
- **1 April 2026 onwards** — brokers reject order requests from unregistered IPs. Live now.

Secondary write-ups still circulate with "1 August 2025" or "1 April 2025" as the date; both are stale or simply wrong. The operative date is 1 April 2026.

---

## What the rules actually say

### The static IP clause, at source

SEBI, section I(d) — brokers shall:

> not permit open APIs and allow access only through a unique vendor client specific API key and static IP whitelisted by the broker to ensure identification and traceability of the algo provider and the end user (i.e. investor)

NSE restates it in section I(e) of the implementation standards, splitting retail from vendor:

> ...access is being provided only through a unique vendor client specific API key and static IP whitelisted by the broker for retail users and unique vendor API key and whitelisted IP for algo providers to ensure identification and traceability of algo provider and the end user i.e. investor.

Note what the clause is *for*: attribution. Every order must be traceable to a person. The static IP is the network-layer half of that, the API key the application-layer half.

### The mechanics — NSE implementation standards, section A

| # | Rule |
|---|---|
| A.1 | Clients "must mandatorily provide the stockbroker with a static IP address(es)" to gain API access |
| A.2 | One primary IP, plus an optional secondary **for redundancy only** |
| A.3 | Multiple API keys per client are allowed (different segments, different algos); each key maps to the same primary/secondary pair, or to its own |
| A.4 | With multiple keys, non-registered algos run through **one** predefined key; the rest are for registered algos |
| A.5 | Whose IP: client-generated algo → the client's. Algo-provider algo → the vendor's or the client's. Broker-generated → the broker's or the client's |
| A.6 | A client may change a mapped IP **not more than once a calendar week** |
| A.7 | **"A static IP can only be mapped to one client at a time."** Sharing is permitted only inside a family, per SEBI/HO/MIRSD/MIRSD-PoD1/P/CIR/2024/169 — self, spouse, dependent children, dependent parents — and needs a written/2FA-validated request to the broker |
| A.8 | "All API sessions shall be compulsorily logged out every day before the start of the next trading day" |

**A.7 is the clause with teeth for this project.** It is a one-to-one mapping between an IP and a human, family excepted.

### Orders per second, and what counts as an algo

- Threshold OPS is **10 per second, per exchange per segment** (NSE section B.2, F). Measured on the broker server's calendar-clock second. A broker may set a lower per-client limit.
- **Below the threshold: no exchange registration** of the algo. Above it, the client registers the algorithm through the broker and gets an exchange algo ID.
- But **everything through the API is an algo order regardless.** NSE FAQ #8: "all orders received via API from clients are considered Algo orders and require appropriate tagging including standardised tagging for cases where the OPS is within the threshold of 10 OPS." There is no "manual order that happens to use the API" category. Below-threshold orders carry the standard tag — first 12 digits `444444444444`, 13th digit `0`, `2` or `4` (FAQ #7).
- A self-developed registered algo may be used for **self and family only**, never for other investors (SEBI I(c)).

> ⚠ **Extraction artefact.** In the text layer of NSE/INVG/67858, item B.3 reads "All such algo orders via API which are below the defined Threshold Order Per Second, require registration with the Exchange" — a negation is lost across the page break. The FAQ, section C.1 of the same circular and Zerodha's own reading all agree the sense is *do not require* registration. Do not quote B.3 from a text dump.

### Who becomes an "algo provider"

- SEBI I(a): the **broker is the principal**; any algo provider, fintech or vendor **acts as its agent** while using the broker's API.
- SEBI III(a): an algo provider "providing the facility to place algo orders with Brokers through API" **must be empanelled with the exchanges**. Criteria are set by the exchanges (NSE/INVG/70309); the empanelment pack includes a self-declaration of cyber or adverse technical incidents for the previous three years.
- SEBI I(d), final bullet: brokers shall "deal with empaneled algo providers only".
- NSE E.1–E.2: the provider registers with **each** exchange it trades on, and registers every algo, each getting a unique algo ID.
- NSE I(h) and FAQ #5: retail algorithms, **including those from empanelled providers, must be hosted on the broker's servers** — "The order messages shall be originated from brokers server." The single exception is the tech-savvy client, who hosts their own algo at their own end, on their own static IP.

### White box vs black box

- **White box / execution algos** — logic disclosed and replicable.
- **Black box** — logic not known to the user and not replicable. The algo provider must **register as a Research Analyst**, maintain a detailed research report per algo, and re-register as a fresh algo on any change to the logic. NSE FAQ #4 adds that an algo provider cannot host black-box algos belonging to third-party RAs.

### Authentication and order types

- **OAuth-based authentication only**; all other mechanisms discontinued (SEBI I(d), NSE I(c)).
- **Two-factor authentication** on API access (SEBI I(d), NSE I(d)).
- Audit trail identifying the actual user for every API order, retained **at least 5 years** (NSE I(a)).
- **Market orders are not permitted** for algos, and IOC is barred in the commodity segment (FAQ #11, citing NSE/MSD/67753). Zerodha additionally rejects orders with market protection set to `0`.
- DMA is out of scope of all of this (NSE J.1).

---

## Broker-by-broker — the three MoneyPlant integrates

### Zerodha / Kite Connect — well documented, high confidence

- Static IP required for **API-based order placement from 1 April 2026**. Orders from an unregistered IP are rejected.
- **Up to two IPs** — one primary (mandatory), one secondary (optional).
- Set at the **developer account / profile level**, covering the apps beneath it — not per app. Zerodha's own support article and its forum notes agree; a third-party guide claiming "1 IP per app" is wrong.
- **Order endpoints only.** "The WebSocket market data stream and other APIs, such as orderbook and positions, can continue to be accessed from any IP address."
- Changes limited to **one per calendar week**, mirroring NSE A.6.
- Family sharing supported through a single developer account, behind a declaration that the IPs are used only by the holder and immediate family.
- **10 OPS enforced per Kite client ID** (not per app); excess requests get HTTP **429**. Iceberg orders count as one. Order slicing capped at 10 slices.
- **IPv6 gotcha:** if the host egresses over IPv6 while only the IPv4 address is whitelisted, orders are rejected. Whitelist what actually leaves the box.

### Alice Blue — partially confirmed, community sources

- Static IP registered in the **A3 developer portal** (`a3.aliceblueonline.com`). This is the same new Open API / a3 stack the project already uses; Alice Blue staff are actively telling users on the old API to migrate.
- Rejection surfaces as `{'stat': 'Not_Ok', 'emsg': 'IP restriction: You are not allowed to place the order'}`, and support diagnoses it as requests arriving from an IP other than the registered one.
- A user report states "Other API features are working correctly. The issue occurs only when placing an order" — consistent with Zerodha, but **there is no official Alice Blue statement** that non-order endpoints are exempt. Treat as likely, not settled.
- **Number of IPs allowed is not publicly documented.** Check the portal.

### Paytm Money — unconfirmed

- Developer portal at `developer.paytmmoney.com`; a user may create **up to five apps**.
- **No primary-source confirmation of its static IP rules was found** — not in the developer portal, not in a support article. Vendor blogs list Paytm Money among brokers requiring whitelisting, which is what the regulation compels, but that is inference rather than documentation.
- **Open item:** log in and read the app settings. Cheap to check, and it is the only one of the three with nothing behind it.

---

## What this means for MoneyPlant today

**Nothing needs to change.** The app reads positions, holdings and margins and draws payoff curves. It sends no order messages, so it is neither a client algo nor an algo provider, and the static-IP mandate has nothing to bite on.

Three things already line up with the framework, by accident or by earlier reasoning:

- **A.8, daily API session logout.** Broker tokens die daily under SEBI rules anyway, which is why sessions are in-memory. `SessionStore.isFresh` restores only sessions created on the same IST calendar day (`SessionStore.java:47-49`), so `MP_SESSION_STORE` cannot carry a session across a trading day even when enabled. That is A.8-shaped behaviour without having aimed at it.
- **OAuth-only plus 2FA.** All three broker integrations are redirect flows, and MoneyPlant's own sign-in is Google OIDC.
- **Unique per-client API keys.** Step 3d gave every user their own broker app and their own key. SEBI I(d) asks for exactly that. The decision was taken on redistribution grounds — see `CREDENTIALS-STEP3D.md` — and it happens to satisfy the clause too.

One correction to carry back: **`DEPLOY-STEP3.md` and `CLAUDE.md` both call the static IP a SEBI requirement.** It is a requirement of the deployment (DNS, TLS, three redirect URIs), and it would become a SEBI requirement the day orders are added. It is not one now.

## What changes if orders are ever added

Order placement is currently out of scope — CLAUDE.md lists "propose-and-confirm order execution" as deferred until a risk module exists. That deferral is now doing more work than it was asked to. Three walls, in ascending order of severity:

**1. Order hygiene — annoying, tractable.** No market orders. Market protection must not be `0`. 10 OPS ceiling with 429s. Standard algo tagging on every order. Five-year audit trail identifying the actual user.

**2. One static IP, one client — this is the wall.** NSE A.7 maps a static IP to exactly one client, family excepted. MoneyPlant runs on a single OCI VM with a single reserved egress IP, and is deliberately multi-user: two allow-listed accounts today, more intended. The moment two non-family users place orders through that VM, both users' orders arrive at their brokers from one IP registered to whichever of them whitelisted it — and the other user's broker rejects, correctly, because that IP is not mapped to them.

There is no clever fix inside the current architecture. The options are:

- **Family only.** Everything works unchanged; A.7's exception covers it exactly. The narrowest and by far the cheapest answer.
- **A dedicated egress IP per user** — a per-user outbound proxy, each user whitelisting their own. Technically possible, costs one IP per user per month, and turns "add a user" into an infrastructure change plus a weekly-limited whitelist edit at their broker.
- **Each user runs their own instance.** Honest, and it abandons the hosted-product shape decided on 29 Jul 2026.

Note this is also where read-only multi-tenancy stops being free: the app is multi-user *because* reads have no IP rule to violate.

**3. Algo-provider empanelment — near-fatal for a hosted product.** Placing orders on behalf of another person through a broker's API makes MoneyPlant an algo provider and, by SEBI I(a), the broker's agent. That means empanelment with each exchange, registration of every algo with a unique ID, broker due diligence before onboarding, brokers permitted to deal with empanelled providers only — and NSE I(h): the algos must run **on the broker's servers**, with order messages originating there. A self-hosted OCI VM placing orders for other people does not fit the shape at all.

The lane that stays open is the one the regulation carves out on purpose: a **tech-savvy investor** running their own algo, on their own static IP, at their own end, for **self and family only**. Below 10 OPS it needs no algo registration — only the static IP and the tagging. Everything MoneyPlant might plausibly want to do lives comfortably inside it, provided "users" means "me and my family".

**And one adjacent trap for Step 8.** LLM-driven analysis offered to other users, where the user cannot see or replicate the logic, is a **black box** algo the moment it drives orders — which pulls in Research Analyst registration and a maintained research report per algo, re-registered on every logic change. That compounds the SEBI RA/IA exposure already flagged under Open decisions in CLAUDE.md. It does not touch analysis that only informs a human who then trades manually elsewhere.

## Open items

1. **Read Paytm Money's app settings for its static IP rules.** The only one of the three with no primary source. Do it during the next connect.
2. **Confirm Alice Blue exempts non-order endpoints**, ideally from Alice Blue rather than from a forum thread. Everything MoneyPlant calls there is a read.
3. **Confirm how many IPs Alice Blue accepts** — NSE allows a primary and a secondary; whether Alice Blue exposes both is unknown.
4. **Check the OCI VM's actual egress IP family.** If anything ever egresses over IPv6 while an IPv4 address is whitelisted, orders are rejected. Irrelevant while read-only; a half-hour of confusion later.
5. **NSE/INVG/69255 (22 Jul 2025) has not been read in full** — only the paragraphs the FAQ quotes (2.8 and 14). If order placement is ever seriously considered, read it end to end before designing anything.
