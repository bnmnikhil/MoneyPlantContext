# Groww: certification dossier (CERT-01)

**Read 11 Oct 2026**, from Groww's published Trade API reference (`groww.in/trade-api/docs/curl`, the Python SDK
introduction, the Portfolio and Margin pages), Groww's own blog and X posts on static IPs, and two third-party
integrators' setup guides (OpenAlgo, StocksDeveloper). Nothing here has been seen against a live account.
Status: **documented, not certified; the login gate fails as the rule is written. Owner decision needed before
any simulator or adapter work** (`NEXT-10.md` N10 step 2).

Read "The decision" first.

## The decision

`memory/browser-redirect-brokers-first.md` admits new brokers **whose login is a browser redirect**. Groww's
retail Trade API has **no browser-redirect login** for a user's own API key. A third-party OAuth endpoint
(`groww.in/oauth/authorize`) is mentioned only by an API catalogue (apis.io), not by Groww's own reference, and
no integrator uses it; treat it as a partner-only path until Groww says otherwise.

What Groww documents instead, and what each would mean for GoldenBook:

| Route | What the user does | What GoldenBook holds | Fit with the rule |
|---|---|---|---|
| **A. API key + secret, daily approval** | Once: generate a key and secret, paste both into Settings (as for Kite). Daily: approve the key on Groww's *Cloud API Keys* page, then press Connect in GoldenBook | Key and secret, encrypted, as for Kite and Upstox | **No secret that logs into Groww passes through GoldenBook** (the user's password, PIN and OTP stay at Groww), and the user consents each day at Groww. But it is not a redirect: two tabs, and an order-capable token at the end, as with every broker. Closest to the rule's intent. |
| **B. TOTP seed** | Once: paste the TOTP token and seed | A seed that mints a fresh token **every day with no user action** | A standing, order-capable credential. This is what the rule holds back (Kotak's TOTP). **Do not use.** |
| **C. Daily access token** | Daily: generate a token on Groww and paste it into GoldenBook | A 1-day token, nothing long-lived | Safest to hold, worst to use: a copy-paste every morning. |

**Recommendation: route A**, as an owner-approved, Groww-only exception: the rule's purpose (no login secret
passes through GoldenBook; the user consents daily at the broker) holds, only the mechanism differs. If the owner
declines, Groww is `deferred` and the plan's roster moves to the next eligible broker.

**Second blocker, independent of the login:** every user pays Groww **₹499 a month plus taxes** for a Trading API
subscription before any call works. That is a real cost to a GoldenBook user, unlike Kite's ₹0 personal tier, and
the setup guide and the catalogue must say so up front.

## Eligibility (`BROKER-EXPANSION-PLAN.md` hard gate)

| Gate | Evidence | State |
|---|---|---|
| 1. Data-only key without a static IP | Groww's guide and its 1 Apr 2026 post scope the static IP to **order placement** ("Order placement must now come from a static, whitelisted IP"). But OpenAlgo's guide shows an *Add/Update Static IP* step during key generation, and StocksDeveloper says every account needs one (₹100 a month for an IPv6 pair). Whether the field can be left empty is not documented. | **Open. Needs CERT-02:** create a key on a real account and record whether the IP field is required. |
| 2. Login and renewal from any IP | Token endpoint `POST /v1/token/api/access`; nothing IP-bound documented. | Documented, not observed. |
| 3. Positions and holdings from a changing IP | Groww's own pages say the IP is for orders; nothing says reads are exempt in so many words. | **Needs CERT-03.** |
| 4. IP limited to order endpoints | As 1. | Documented by implication only. |
| 5. Hosted multi-user use allowed | The reference is silent. Third-party platforms (OpenAlgo, StocksDeveloper, Quantiply on Groww's own blog) connect users' keys, which suggests it is tolerated. | **Open: CERT-04. Needs Groww's written answer.** |
| 6. Evidence beyond marketing pages | Reference pages plus integrators' guides. | Open until CERT-02/03. |
| **Owner rule: browser-redirect login** | None for retail keys (see above). | **Fails as written. Owner decision.** |

## Login (route A)

1. **Once, at Groww:** profile → Settings → *Trading APIs* → *Generate API keys* → API key and secret. Requires an
   active Trading API subscription.
2. **Daily, at Groww:** approve the key on the *Cloud API Keys* page. Approvals reset with the token.
3. **Server:** `POST https://api.groww.in/v1/token/api/access` with `Authorization: Bearer <api key>` and body
   `{"key_type":"approval","checksum":"<sha256(secret + timestamp)>","timestamp":"<epoch seconds>"}`. Returns the
   access token. The token endpoint allows **150 requests a day** and 5/s, 30/min.

**Token:** expires **daily at 06:00 IST** (a fixed clock time, unlike Dhan's 24 hours). At most 5 active tokens.
No refresh. GoldenBook's same-day-IST session rule (`PostgresSessionStore`) fits: a session made before 06:00 dies
at 06:00, which the gateway must classify as `SESSION_EXPIRED`.

**No `state` and no callback:** there is no redirect, so the connect nonce and the callback controller are not
needed. The "Connect" button calls the token exchange directly and reports "approve the key at Groww first" when
the exchange is refused.

## Reads (all `Authorization: Bearer <token>`, `Accept: application/json`, `X-API-VERSION: 1.0`)

Base URL `https://api.groww.in/v1`. Every body is `{"status":"SUCCESS","payload":{…}}`.

- **Positions:** `GET /positions/user?segment=FNO|CASH` → `payload.positions[]`: `trading_symbol`, `exchange`,
  `symbol_isin`, `product`, `quantity`, `credit_quantity`/`credit_price`, `debit_quantity`/`debit_price`,
  `carry_forward_credit_quantity`/`_price`, `carry_forward_debit_quantity`/`_price`, `net_carry_forward_quantity`,
  `net_price`, `net_carry_forward_price`, `realised_pnl`.
  - **No last price and no unrealised P&L.** `pnl` and `dayChange` need a quote, as at Paytm: the Live Data LTP
    call, batched. Until it is wired, `priceKnown` must be false, never a zero.
  - The reference types the prices as `int` while the example shows `12400` for RELIANCE: **paise or rupees is
    unsettled** (the field table says rupees).
  - **`net_price` versus the true entry:** with separate carry-forward fields, `net_price` may be rebased like
    Alice Blue's `netAveragePrice`. Reconstruct the entry from the credit, debit and carry-forward pairs, and
    check against a live book.
- **Holdings:** `GET /holdings/user` → `payload.holdings[]`: `isin`, `trading_symbol`, `quantity`, `average_price`,
  `t1_quantity`, `pledge_quantity`, `demat_free_quantity`, `demat_locked_quantity`, `groww_locked_quantity`,
  `repledge_quantity`, `corporate_action_additional_quantity`, `active_demat_transfer_quantity`. No last price,
  so a quote again.
- **Margins:** `GET /margins/detail/user` → `clear_cash`, `net_margin_used`, `collateral_used`,
  `collateral_available`, `net_fno_margin_used`, `span_margin_used`, `exposure_margin_used`, the per-product
  balances. Proposed mapping: `used` = `net_margin_used`, `cash` = `clear_cash`, `collateral` =
  `collateral_available`; `available` has **no single field** and must be confirmed live (candidates:
  `option_sell_balance_available`, or `clear_cash + collateral_available − net_margin_used`).
- **Instruments:** a downloadable instrument file (*Instruments* section); shape not read yet.

## Errors

`{"status":"FAILURE","error":{"code":"GA001","message":"…","metadata":null}}`. The code list (Annexures) has not
been read. Classify on the HTTP status first, as for every broker; which status a lapsed 06:00 token returns is
unknown.

## Rate limits

Per second / per minute: authentication 5/30, orders 10/250, live data 10/300, other non-trading 20/500.

## What only a live account can settle

1. **Is the static-IP field required when the key is created?** (CERT-02, gate 1.)
2. Do positions, holdings and margins answer from a changing IP? (CERT-03.)
3. Are position prices in paise or rupees, and is `net_price` the true entry for a carried leg?
4. Do `quantity`, `t1_quantity` and `pledge_quantity` overlap in holdings?
5. The status and code of an expired token, and of an exchange refused for lack of approval.
6. Which margin field means "available".

## Not in the first adapter

Orders, smart orders, historical data, backtesting. Live Data is needed for marks only (LTP), not as a chain.

## Next

1. **Owner:** route A as a Groww-only exception, or defer Groww. And: is ₹499 a month per user acceptable to
   offer at all?
2. If A: CERT-02/03 on a friend's account (gate 1 is a hard stop if the IP is mandatory), CERT-04 by email.
3. Then, per N10: broker-sim profile (synthetic), adapter merged `internal`, catalogue copy that states the cost
   and the daily approval.

Sources: [Groww Trade API reference](https://groww.in/trade-api/docs/curl) ·
[Portfolio](https://groww.in/trade-api/docs/curl/portfolio) · [Margin](https://groww.in/trade-api/docs/curl/margin) ·
[Python SDK introduction](https://groww.in/trade-api/docs/python-sdk) · [Trade API pricing](https://groww.in/trade-api) ·
[Groww: static IP for trading APIs](https://groww.in/blog/static-ip-api-trading-setup) ·
[Groww on X, 1 Apr 2026 rules](https://x.com/TradeWithGroww_/status/2038996435870621738) ·
[OpenAlgo Groww guide](https://docs.openalgo.in/connect-brokers/brokers/groww) ·
[StocksDeveloper Groww guide](https://stocksdeveloper.in/documentation/supported-brokers/groww/) ·
[apis.io Groww authentication](https://apis.io/apis/groww/groww-authentication-api/)
