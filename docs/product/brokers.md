# Brokers

Five brokers are live. Each is a self-contained adapter behind one interface, so adding a broker is writing
one package. The research behind each lives in the dossiers and in `tradestack/docs/`.

## At a glance

| Broker | Added | Login | State carried through login | Session life | Positions price | Option chain |
|---|---|---|---|---|---|---|
| **Zerodha Kite** | Original | Redirect, key and secret | Yes (`redirect_params`) | About a day | In the payload | No |
| **Alice Blue** | Original | Redirect, app code and secret | **No**, so one pending connect at a time | About 24 h | In the payload | **Yes**, the only chain source |
| **Paytm Money** | Original | Redirect, key and secret | Yes (`state`) | About a day | **Not in the payload**; a quote call prices it | No |
| **Upstox** | **6 Oct 2026** | Standard OAuth | Yes (`state`) | Until **03:30 IST** next day | In the payload | No |
| **Dhan** | **6 Oct 2026** | Three-step consent flow | **No**, so one pending connect at a time | **24 h from issue**, renewable | **Not in the payload**; a paid Data API prices it | No |

**Upstox and Dhan have never met a live account.** Their shapes come from published documentation and a
simulator. The open questions are listed in their dossiers
([Upstox](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/research/UPSTOX-DOSSIER.md),
[Dhan](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/research/DHAN-DOSSIER.md)).

## What each broker gets wrong (and the app corrects)

| Broker | The trap | What the adapter does |
|---|---|---|
| Kite | `quantity` in holdings excludes pledged and T+1 stock | Adds them back |
| Kite | The official SDK throws the JSON away and could not be repointed | Replaced by a plain REST client; the archive now holds Kite's own bytes |
| Alice Blue | `netAveragePrice` is the previous close, not the entry | Reconstructs the real entry from overnight and day prices |
| Alice Blue | An expired token is a plain-text `401`, and the SPA logs the user out on any 401 | Converts it to a "session expired" warning before it can escape |
| Alice Blue | The option chain is nested one level deeper than every other call | Reads `result[0].data` |
| Paytm | `last_traded_price` in positions is always `0.0` | Prices each leg from the live-price endpoint, in one batched call |
| Paytm | A percent-encoded `pref` silently returns no quotes | Sends colons and commas literally; a test pins the URL |
| Upstox | Documentation is silent on whether `average_price` is the entry | Assumes it is; a test names the assumption |
| Dhan | No price on positions or holdings; quotes need a paid plan | Rows arrive unpriced (`priceKnown = false`); Dhan's own profit figure still shows |
| Dhan | The fund field is spelled `availabelBalance` | Reads that spelling |
| Dhan | The login needs the user's own client id | The registration carries an optional client id |
| Dhan | Errors carry a code (`DH-901` for a dead token) but no documented HTTP status | Classifies on the code, never the status |

## The shape of an adapter

Every broker implements the same small set of interfaces (in `broker/spi/`):

- **`BrokerGateway`**: positions and holdings (required), margins and the F&O instrument list (optional,
  declared as capabilities).
- **`BrokerAuthProvider`**: builds the broker's login URL.
- A session service and a callback controller for the redirect.
- A raw reader and parser, so the same mapper serves live calls and the archive.

An adapter is **stateless**: the user's session and credentials arrive as parameters, never fields, which is
what lets one set of beans serve every user and every account.

## Planned

| Broker | NSE rank | State |
|---|---|---|
| Groww | 1 | Next. Its API costs ₹499 a month, and reading without a static IP is unproven |
| FYERS, 5paisa | 21, 16 | Planned; login types not yet checked |
| Kotak Neo, Motilal Oswal | 6, 10 | **On hold**: their logins would pass the user's TOTP, MPIN or trading password through GoldenBook |
| Angel One | 3 | Waiting on a portal check: its app form asks for a static IP |

The ordered plan and the eligibility rule (a user must be able to create a data-only app without a static IP)
are in [`BROKER-EXPANSION-PLAN.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/BROKER-EXPANSION-PLAN.md).
