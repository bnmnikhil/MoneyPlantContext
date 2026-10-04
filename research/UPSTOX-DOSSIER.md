# Upstox: certification dossier (CERT-01)

**Read 4 Oct 2026**, from Upstox's published API reference (`upstox.com/developer/api-documentation/…`).
Nothing here has been seen against a live account. Status: **documented, not certified.**
The simulator profile (`broker-sim`, `UpstoxSim`) is built from this and marks each assumption.

## Eligibility (`BROKER-EXPANSION-PLAN.md` hard gate)

| Gate | Evidence | State |
|---|---|---|
| 1. Data-only app without a static IP | The 21 Sep research; Upstox's algo-trading announcement excludes standard holdings, positions, funds. | **Needs CERT-02**: create an app and record whether the form asks for an IP. |
| 2. Login and renewal from any IP | Standard OAuth, nothing IP-bound. | Documented. Use standard OAuth, **not** the one-year Analytics Token (that one is IP-bound for account data). |
| 3. Positions and holdings from a changing IP | Documented. | **Needs CERT-03**. |
| 4. IP limited to order endpoints | Per the announcement. | Documented. |
| 5. Hosted multi-user use allowed | Not read. | **Open: CERT-04.** Ask Upstox, or read the API terms. |
| 6. Evidence beyond marketing pages | Reference pages only so far. | Open until CERT-02/03. |

## Login (standard OAuth)

- **Dialog:** `GET https://api.upstox.com/v2/login/authorization/dialog` with `client_id` (the API key),
  `redirect_uri` (must match the registered one exactly), `response_type=code`, optional `state`.
- **Redirect back:** `redirect_uri?code=…&state=…`. `state` is returned, so the connect nonce rides through it
  (unlike Alice Blue). QR-code login is incompatible with this flow.
- **Exchange:** `POST https://api.upstox.com/v2/login/authorization/token`, `application/x-www-form-urlencoded`:
  `code`, `client_id`, `client_secret`, `redirect_uri`, `grant_type=authorization_code`.
  The response is a **bare object with no `status` envelope**: `email, exchanges, products, broker, user_id,
  user_name, order_types, user_type, poa, is_active, access_token, extended_token`. `user_id` is the account label.
- **Token life:** until **03:30 IST the next day**, whatever time it was issued. No refresh. (Kite and Alice Blue are
  about 06:00.)
- **One registration, one redirect URL**, as with the other brokers. Ours would be `https://goldenbook.in/upstox/callback`.

## Reads (all `Authorization: Bearer <token>`, `Accept: application/json`)

| Call | Path |
|---|---|
| Positions | `GET /v2/portfolio/short-term-positions` |
| Holdings | `GET /v2/portfolio/long-term-holdings` |
| Funds and margin | `GET /v2/user/get-funds-and-margin?segment=SEC` (`SEC` equity, `COM` commodity; omit for both) |

Envelope: `{"status":"success","data":…}`.

- **Positions** (`data[]`): `exchange, multiplier, value, pnl, product, instrument_token, average_price, buy_value,
  overnight_quantity, day_buy_value, day_buy_price, overnight_buy_amount, overnight_buy_quantity, day_buy_quantity,
  day_sell_value, day_sell_price, overnight_sell_amount, overnight_sell_quantity, day_sell_quantity, quantity,
  last_price, unrealised, realised, sell_value, trading_symbol, tradingsymbol, close_price, buy_price, sell_price`.
  The price is in the payload, so no second quote call is needed (unlike Paytm).
- **Holdings** (`data[]`): `isin, cnc_used_quantity, collateral_type, company_name, haircut, product, quantity,
  trading_symbol, tradingsymbol, last_price, close_price, pnl, day_change, day_change_percentage, instrument_token,
  average_price, collateral_quantity, collateral_update_quantity, t1_quantity, exchange`.
- **Funds**: `data.equity` and `data.commodity`, each `used_margin, payin_amount, span_margin, adhoc_margin,
  notional_cash, available_margin, exposure_margin`. **The funds service is down 00:00 to 05:30 IST** and answers
  `UDAPI100072`. The app must show "unavailable", not zero, in that window.
- **Instrument master:** gzipped JSON at `https://assets.upstox.com/market-quote/instruments/exchange/NSE.json.gz`
  (also `complete`, `BSE`, `MCX`), refreshed about 06:00 IST. F&O rows: `segment=NSE_FO, instrument_key
  ("NSE_FO|36708"), trading_symbol ("IDEA 22 CE 25 JAN 24"), underlying_symbol, underlying_key, expiry (epoch
  milliseconds, end of the expiry day IST), strike_price, lot_size, instrument_type (FUT/CE/PE), weekly, tick_size`.

## Errors

- Invalid or expired token: HTTP **401**, code **`UDAPI100050`**.
- Rate limit: HTTP **429**, code **`UDAPI10005`**.
- The error **body shape was not on the pages read.** The simulator uses
  `{"status":"error","errors":[{"errorCode","message","propertyPath","invalidValue"}]}`, recalled, **unverified**.
  The adapter must classify on the HTTP status first, as the Alice Blue gateway does, and never on the body.

## What only a live account can settle

1. **Does the app form ask for a static IP?** (CERT-02, the gate.)
2. **Is `average_price` on a carried position the real entry, or a mark-to-market basis?** The docs are silent. This
   is the trap Alice Blue falls into; getting it wrong puts today's P&L profile on the payoff chart.
3. **Do `quantity`, `t1_quantity` and `collateral_quantity` overlap?** The docs say `quantity` is the "total holding
   quantity" and list the others beside it. The simulator assumes they are disjoint, as at Kite. Wrong either way
   double counts or drops shares.
4. The real error body, and the real code for a bad token exchange.
5. Whether `extended_token` is issued to a normal app (the doc example shows one; it may be a different product).
6. The real `tick_size` unit in the instrument file (the simulator uses 5.0, paise).

## Not in the first adapter

Market quote and option chain (Upstox returns greeks, free) are a later phase. The first adapter is login,
positions, holdings and margins, with the instrument master only for contract resolution. See
`memory/free-market-data-options-researched.md`.

## Next

- CERT-02/03/04 need a real Upstox account (a friend's, per the 4 Oct decision) and a written answer on hosted use.
- Meanwhile the adapter can be built against the simulator and merged `hidden` (FOUND-06 first).
