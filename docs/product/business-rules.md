# Business rules

The rules the application follows, and the reasons. Where a rule came from a measured surprise at a broker
it says so. The exact, current wording is in [`CLAUDE.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/CLAUDE.md)
and the linked memory notes.

## The principle behind all of them

> **A figure the app cannot know is shown as unknown, never as zero.**

Brokers fail quietly: a quote call returns an empty list, a field is absent, a subscription is missing. A
zero that looks real is the worst failure for a finance tool, so every layer carries "is this known?" with the
number (`priceKnown` on a position, a dash in the table, a `?` beside a partial total). The memory note
`an-unmeasured-zero-is-a-claim` is the origin.

## Profit and loss

Brokers disagree on what "P&L" means, so every position carries two columns whose meaning is fixed, and each
broker's adapter fills whichever half its broker withholds.

| Column | Meaning | Unit |
|---|---|---|
| `pnl` | Lifetime profit or loss since the position was opened | rupees |
| `dayChange` | Today's movement only | rupees (not per unit) |

The trap is that the same position can show opposite signs. Example measured at Alice Blue: 650 units
bought at 5.20 and trading at 7.25 are **up ₹1,332 since entry and down ₹1,495 today**. Never use a broker's
P&L field without checking which of the two it means.

A second trap sits next to it: some brokers report an "average price" that is not the entry price but a
mark-to-market basis (Alice Blue's `netAveragePrice` equals the previous close for anything carried overnight).
The payoff chart needs the real entry price, so each adapter reconstructs it, and **where a broker's
documentation does not say which it is (Upstox's `average_price`, Dhan's `costPrice`), the code assumes "real
entry" and a test names the assumption** until a live account settles it.

## Holdings quantity

`qty` is the whole holding, **pledged and T+1 shares included**, and `pledgedQty` is a breakdown of it, never an
addition. Brokers differ: Kite's `quantity` excludes pledged and T+1 stock and reports them separately, so
reading it alone shows a fully pledged holding as zero shares. Paytm's `quantity` is already the total. The
adapters normalise so any consumer can read `qty` and be right.

## Margin

Three of the five margin fields mean different things per broker.

| Field | Meaning | Note |
|---|---|---|
| `available` | What the broker says can still be used | Different source field at every broker |
| `used` | What the broker has blocked | **The only field that means the same thing everywhere** |
| `cash` | Cash balance | Alice Blue's and Dhan's are *opening* balances, Kite's and Paytm's are live and can be negative when the book is funded on collateral. So cash is shown per broker and **never summed**. |
| `collateral` | Pledged collateral | Upstox sends no collateral figure, so it shows as 0 by absence |
| `total` | `available + used` | GoldenBook's own invention; no broker supplies it |

### The margin estimate

The risk view does not rely on the broker's headline. It estimates margin **bottom-up** from the positions:
SPAN plus exposure, where SPAN is the worst loss across the exchange's own sixteen scenarios (seven price
moves, each with volatility up and down, plus two extreme moves) over the published scan ranges, and
exposure is charged leg by leg. Options are priced with Black-Scholes at a volatility solved from their own
market price, never at expiry value. It is calibrated on two real books and runs lower than a broker's own
calculator (SPAN about 24% lower), because the exchange widens the published ranges using a volatility
history this system does not have. The column deliberately **does not add up to the broker's bill**, and the
screen says so; the real bill is shown beside it.

## Payoff

- **One chart per strategy**, where a strategy is the legs held in **one account on one underlying**. Two
  accounts holding the same strike are two strategies, never netted.
- **Spot** comes from the user's own brokers first (a quote or the option chain's own spot field), and is never
  invented. Put-call parity is not used: it recovers the forward, which measured 33 points above the real spot.
  If no connected broker can quote the underlying, the page says so instead of drawing a chart around a made-up
  number.
- **Different expiries share one terminal-price scenario**, and the page says so; a displayed loss is not a
  guaranteed cap across those dates.
- **Optional holdings** can be included as equity legs at their cost, with explicit handling of overlaps.
- **Chart range** defaults to spot ±10% for indices and ±15% for stocks, widened to include every strike and
  breakeven. Changing the view never changes the summary figures.

## Premium left

Premium left is the negated market value of the option legs (a short position's premium is money the user has
collected and may still lose back). A leg that could not be quoted is excluded and the total is marked partial
with a `?`; a missing short adds and a missing long subtracts, so a partial figure is not a floor.

## The Overview page

The Overview answers "what should I do?". Under the totals it shows one table of accounts (P&L and
capital side by side) and a **Needs attention** band:

- **Margin pressure**: any account using 75% or more of its own capital. Capital is held per account, so
  the summary also names the **tightest** account beside the combined percentage: 27% overall can hide
  one account at 84%.
- **Expiring soon**: open legs expiring within the next 7 calendar days (Indian time), by account and
  expiry, with the next expiry after that.
- **Biggest moves today**: the three legs with the largest day P&L, at least ₹100, priced legs only.
- **To fix**: a broker that is set up but not connected, an expired session (reconnect), a broker that
  could not be read (temporary, never "reconnect"), legs with no current price, and stale margin
  estimates.

When nothing needs attention the band is one line saying what was checked. Biggest moves can still
appear beside it: a big move is information, not a problem.

## Sessions and sign-in

- **The application login expires at midnight IST**, and polling cannot carry it past midnight. A foreground
  tab notices within a minute.
- **A broker session** lasts as long as the broker allows (about a day; see [Brokers](brokers.md)). The app
  restores only sessions created *today* in IST, which is stricter than any broker's real expiry: restoring a
  dead token gives a confusing failure, while expiring early costs a login the user was making anyway.
- **Expiry is a warning, not an error.** One broker's dead token never fails the page; the others still show,
  with a reconnect prompt for the one that expired.

## Who may sign up

`GB_SIGNUP_MODE` is one of `allowlist`, `open` or `closed`. Production has been `open` since 3 October 2026. A
user row can be disabled and is refused at the next sign-in. There is no per-request user check by owner
decision: a disabled user's already open web session lasts until midnight IST.

## Which brokers a user can see

Every broker has a rollout state, `hidden < internal < staging < available`, and is usable only in the
environments below its rung: `internal` locally, `staging` also on staging, `available` everywhere. The state is
enforced on the backend: the catalogue, the credential screens, the connect flow and every read of a stored
session all consult it, so a broker that is not rolled out behaves as if it did not exist and a session saved
for it is invisible rather than failing. It is switched per deployment with `GB_ROLLOUT_<BROKER>`.

## Read-only, in code

A rule worth stating because it is enforced, not merely intended: no gateway has a write method, the broker
catalogue declares capabilities explicitly, and an unsupported optional read becomes an `UNSUPPORTED_CAPABILITY`
error rather than a fabricated empty result.
