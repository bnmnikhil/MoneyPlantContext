# L1 — broker consent emails

**Drafted 2 Oct 2026. Not sent.** Fill the `[brackets]`, send from the address that will
appear as the grievance contact (E6), then record the sent date below. Paste each reply
**verbatim** into `BROKER-API-TERMS-MULTI-USER.md` under the broker's section.

| Broker | To | Sent | Reply |
|---|---|---|---|
| Zerodha | `kiteconnect@zerodha.com` | — | — |
| Alice Blue | `api@aliceblueindia.com` | — | — |
| Paytm Money | `openapi.care@paytmmoney.com` | — | — |

Every claim below was checked against `origin/main` on 2 Oct. **Before sending, confirm
that L18 (the cross-user spot cache) is fixed or will be fixed before launch.** The Paytm
email says market data is never shown to another user, and today that is not quite true.

---

## Zerodha

**Subject:** Multi-user access approval: read-only portfolio viewer using each user's own Kite Connect app

Hello Kite Connect team,

I'm building MoneyPlant (`https://[domain]`), a read-only portfolio viewer for Indian F&O
traders. It shows a user's positions, holdings and margins from their brokers in one
place, with option payoff charts. I plan to open it to the public on [date]. Before I do,
I'd like to confirm that the way it uses Kite Connect is permitted, or what approval it
needs.

How it works:

- **Each user registers their own Kite Connect app** under their own Zerodha account. There
  is no shared app key. The user's app has MoneyPlant's callback as its redirect URL.
- The user enters their own API key and secret in MoneyPlant. The secret is stored
  encrypted (AES-256-GCM, with the key held outside the database). It is used only to
  complete the login handshake that the user starts themselves, and it is never returned
  to any browser.
- **Read-only.** MoneyPlant calls positions, holdings, user margins (equity segment),
  instruments and the margin calculator. It has no order placement, modification or
  cancellation code.
- Each user sees only their own data. Nothing from Kite is shown to any other user or to
  the public. Copies of a user's own portfolio are stored only to show that same user
  their history.
- Access tokens are stored encrypted and not reused after the trading day. Users can
  delete their credentials at any time.
- Hosted in India on a single server ([Oracle Cloud, Hyderabad]).

My questions:

1. Is this use permitted under the Kite Connect terms, given §4(b) on credentials being
   used only by the client?
2. If multi-user access needs compliance approval, what is the process, and does it change
   which tier each user needs (Personal vs Connect)?
3. Would you rather users never give MoneyPlant their API secret? I could compute the
   session checksum in the user's browser so the secret never reaches my server.

I expect [number] users in the first months. The service is [free / planned pricing].

Thanks,
[Name]
[Contact email · phone]

---

## Alice Blue

**Subject:** Third-party platform approval: read-only viewer using each client's own ANT API app

Hello Alice Blue API team,

I'm building MoneyPlant (`https://[domain]`), a read-only portfolio viewer for Indian F&O
traders, and I plan to open it to the public on [date]. Your API terms (section 2) allow
building a platform offered to other Alice Blue clients, and section 4 restricts disclosing
API credentials. I'd like to confirm how MoneyPlant should be set up.

How it works:

- **Each client creates their own ANT API app** and has it activated by your admin team.
  They then enter its app code and secret in MoneyPlant. The secret is stored encrypted
  (AES-256-GCM, with the key held outside the database) and used only to complete the
  login the client starts themselves.
- **Read-only.** MoneyPlant calls positions, holdings, limits, the NFO contract master and
  the option chain. It has no order placement code.
- A client sees only their own data. Option-chain data fetched with a client's session is
  shown only to that same client, including next to positions they hold at another broker.
  It is never shown to other users or published.
- Hosted in India on a single server.

My questions:

1. Is this permitted with each client's own app? Or should MoneyPlant register as a
   **vendor** app, as described in your Vendors documentation?
2. Is it acceptable to show a client their own option-chain data next to positions they
   hold at another broker?
3. If approval is needed, what does the process involve?

Thanks,
[Name]
[Contact email · phone]

---

## Paytm Money

**Subject:** Permission for a read-only multi-user platform built on Paytm Money Open API

Hello Paytm Money Open API team,

I'm building MoneyPlant (`https://[domain]`), a read-only portfolio viewer for Indian F&O
traders, and I plan to open it to the public on [date]. I couldn't find published terms of
use for the Open API, so I'd like to confirm the following is permitted.

How it works:

- **Each user creates their own Open API app** and enters its key and secret in MoneyPlant.
  The secret is stored encrypted and used only for the login the user starts themselves,
  which includes their own password and OTP.
- **Read-only.** MoneyPlant calls positions, holdings, funds, the user details endpoint,
  the public security master, and the live price endpoint (LTP mode). It has no order
  placement code.
- Live prices fetched with a user's session are shown only to that same user, including as
  the spot reference on payoff charts for positions they hold at other brokers.
- Hosted in India on a single server.

My questions:

1. Is this use permitted, and is any approval or registration needed?
2. Is it acceptable to use a user's live prices to chart that same user's positions held
   at another broker?
3. Are there published terms of use or rate limits I should follow?

Thanks,
[Name]
[Contact email · phone]
