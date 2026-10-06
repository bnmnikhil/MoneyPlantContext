# Dhan: certification dossier (CERT-01)

**Read 6 Oct 2026**, from DhanHQ's published v2 reference (`dhanhq.co/docs/v2/…`) and Dhan's support pages.
Nothing here has been seen against a live account. Status: **documented, not certified.**
The simulator profile (`broker-sim`, `DhanSim`) is built from this and marks each assumption.

**Dhan is not a drop-in copy of Upstox.** Three things in this dossier change what the adapter needs:
a third credential, an attribution problem, and prices that sit behind a paid subscription. Read
"Consequences for GoldenBook" first.

## Eligibility (`BROKER-EXPANSION-PLAN.md` hard gate)

| Gate | Evidence | State |
|---|---|---|
| 1. Data-only app without a static IP | The static IP is set through separate APIs (`/v2/ip/setIP`) and needed only for order placement. The key and secret come from `web.dhan.co` -> Profile -> *Access DhanHQ APIs*. | Documented. **Needs CERT-02**: create an app and record whether any IP is asked for. |
| 2. Login and renewal from any IP | Consent flow plus `RenewToken`; nothing IP-bound. | Documented. |
| 3. Positions and holdings from a changing IP | Docs: static IP "Not Required: fetching order details or trade data". | **Needs CERT-03.** |
| 4. IP limited to order endpoints | Orders, Super Orders, Forever Orders only. | Documented. |
| 5. Hosted multi-user use allowed | The docs say nothing about hosted or multi-user use. Dhan has a separate **partner** programme (below). | **Open: CERT-04. Needs Dhan's written answer.** |
| 6. Evidence beyond marketing pages | Reference pages only. | Open until CERT-02/03. |

**Prerequisite on the user's side:** TOTP must be enabled on the Dhan account for the API-key flow. The user's
API key and secret are valid for **12 months** and must be regenerated yearly.

## Login (three steps, the first on the server)

1. **Generate consent** (server): `POST https://auth.dhan.co/app/generate-consent?client_id={dhanClientId}`
   with headers `app_id` (the API key) and `app_secret`. Returns a `consentAppId`. **`client_id` is the user's own
   Dhan client id**, so it is a third credential beside key and secret. Up to **25 consents a day**.
2. **Browser login:** `https://auth.dhan.co/login/consentApp-login?consentAppId={consentAppId}`. The user enters
   Dhan credentials and completes 2FA. The browser is redirected to the **pre-registered Redirect URL** with a
   **`tokenId`**. **No `state` or other passthrough parameter is documented.**
3. **Consume consent** (server): `POST https://auth.dhan.co/app/consumeApp-consent?tokenId={tokenId}` with
   `app_id` and `app_secret`. Returns `dhanClientId`, name, UCC, `givenPowerOfAttorney`, the **access token** and
   `expiryTime`.

**Token:** valid **24 hours from issue** (not a fixed clock time). `PUT https://api.dhan.co/v2/RenewToken`
(headers `access-token`, `dhanClientId`) extends a still-valid token by another 24 hours; an expired one cannot be
renewed. All calls carry `access-token: <JWT>`; the market-feed calls also send `client-id`.

**Partner flow (the hosted route):** a partner is issued `partner_id` and `partner_secret` and runs the same three
steps against `/partner/generate-consent` and `/partner/consume-consent`, with login at
`https://auth.dhan.co/consent-login?consentId=...`. This is the model that would let GoldenBook serve users **without**
each creating an app, but it needs Dhan's approval and is not in the standard docs beyond these endpoints.

## Reads (base `https://api.dhan.co/v2`)

| Call | Path | Notes |
|---|---|---|
| Holdings | `GET /holdings` | Flat array, no envelope. |
| Positions | `GET /positions` | Flat array. |
| Funds | `GET /fundlimit` | One object. |
| Profile | `GET /profile` | Token validity, active segments, **`dataPlan`** status. |
| Last price | `POST /marketfeed/ltp` | Body `{"NSE_FNO":[id,...],"NSE_EQ":[...],"IDX_I":[...]}`; up to 1000 ids; **1 request/s**. |

- **Holdings fields:** `exchange, tradingSymbol, securityId, isin, totalQty, dpQty, t1Qty, availableQty, collateralQty,
  avgCostPrice`. **There is no price field.**
- **Positions fields:** `dhanClientId, tradingSymbol, securityId, positionType (LONG/SHORT/CLOSED), exchangeSegment,
  productType, buyAvg, buyQty, costPrice, sellAvg, sellQty, netQty, realizedProfit, unrealizedProfit,
  rbiReferenceRate, multiplier, carryForwardBuyQty/SellQty/BuyValue/SellValue, dayBuyQty/SellQty/BuyValue/SellValue,
  drvExpiryDate, drvOptionType, drvStrikePrice, crossCurrency`. **There is no last-price field either**, but
  `unrealizedProfit` is present, so Dhan prices the position itself.
- **Funds fields:** `dhanClientId, availabelBalance` (**Dhan's own misspelling**), `sodLimit, collateralAmount,
  receiveableAmount, utilizedAmount, blockedPayoutAmount, withdrawableBalance`.
- **Instrument master:** `https://images.dhan.co/api-data/api-scrip-master.csv` (compact) and
  `api-scrip-master-detailed.csv`; per-segment `GET /v2/instrument/{exchangeSegment}`. Columns include
  `SEM_EXM_EXCH_ID, SEM_SEGMENT, SEM_SMST_SECURITY_ID, SEM_INSTRUMENT_NAME, SEM_TRADING_SYMBOL, SEM_LOT_UNITS,
  SEM_EXPIRY_DATE, SEM_STRIKE_PRICE, SEM_OPTION_TYPE, SEM_CUSTOM_SYMBOL, UNDERLYING_SYMBOL`. **The date format and
  refresh time are not documented.**
- **Enums:** segments `IDX_I`(0) `NSE_EQ`(1) `NSE_FNO`(2) `NSE_CURRENCY`(3) `BSE_EQ`(4) `MCX_COMM`(5) `BSE_CURRENCY`(7)
  `BSE_FNO`(8); products `CNC, INTRADAY, MARGIN` (carry-forward F&O), `CO, BO`.

## Errors

Error body: `{"errorType": "", "errorCode": "", "errorMessage": ""}`. Trading codes: **`DH-901` invalid or expired
token** (the one that means reconnect), `DH-902` Data API subscription required, `DH-903` segment not activated,
`DH-904` rate limited, `DH-905` bad parameter, `DH-907` data unavailable, `DH-908/909/910` server side. The **Data
API** has its own numeric codes: `806` not subscribed, `807` token expired, `808` auth failed, `809` invalid token,
`810` invalid client id, `805` rate limited.
**Not on the pages read: the HTTP status Dhan uses for each.** The adapter must classify on the **error code**, not
the status. This is the opposite of Upstox, where the status is all that is known.

Rate limits: non-trading calls 20/s; Data APIs 5/s and 100,000 a day; the quote calls 1/s.

## Consequences for GoldenBook

1. **A third credential: the client id.** `generate-consent` needs the user's Dhan client id. The wire body
   `{apiKey, apiSecret}` is not enough, so **FOUND-03 (credential fields per broker) is needed for Dhan** after all.
   The client id is an identifier, not a secret: stored in the clear, never write-only. It also ties the registration
   to one Dhan account, so "one app, two accounts" does not apply to Dhan.
2. **Attribution.** The redirect carries only a `tokenId`. If Dhan does not pass `state` through (nothing says it
   does), the callback can only be attributed by Alice Blue's rule: exactly one pending Dhan connect, else refuse. A
   live check must settle whether a query string registered on the Redirect URL survives the round trip. Until
   then, plan for the worst case.
3. **Prices cost money.** Holdings and positions have no last price. The market-feed call needs the **Data API
   subscription, Rs 499 plus tax a month**, per user. The free-with-25-trades offer was discontinued. Without it a
   Dhan user gets quantities, average costs and Dhan's own `unrealizedProfit`, but no live marks, no day change and
   no holdings value. The adapter must say "price unknown" (`priceKnown = false`) rather than a zero, and the
   onboarding guide must say so, the way it will say Groww's API costs Rs 499.
4. **Session life.** 24 hours from issue, renewable while valid. Renewing from the end-of-day job would keep a
   connection alive across days without another login; that is an option, not a requirement.
5. **Static IP and hosted use** are as for Upstox: orders only; hosted terms unanswered (CERT-04). The partner
   programme is the cleaner route if Dhan will grant it.

## What only a live account can settle

1. Does the API-key form ask for a static IP? (CERT-02, the gate.)
2. Does the redirect carry anything but `tokenId`, and can the registered Redirect URL carry a query string?
3. The HTTP status for `DH-901`, and the exact body of the Data API refusal (`806` / `DH-902`).
4. How `totalQty`, `dpQty`, `t1Qty`, `availableQty` and `collateralQty` relate. The simulator assumes
   `dpQty = free + pledged`, `totalQty = dpQty + t1Qty`, `availableQty` the free part, `collateralQty` the pledged
   part. Wrong either way double counts or drops shares.
5. What `costPrice` is for a carried position: the real entry, or a mark-to-market basis (the Alice Blue trap).
   `unrealizedProfit` against `costPrice` and a known price will say.
6. What an empty holdings or positions book answers (an empty array, or an error code).
7. The instrument file's date format and refresh time.
8. Whether `tokenId` and `consentAppId` are single use and how long they live.

## Next

- Build the adapter after FOUND-03, merged `hidden` or `staging`, against the simulator profile.
- CERT-02/03 and the open questions need a real Dhan account (a friend's); CERT-04 needs Dhan's written answer, or
  a partner arrangement.
