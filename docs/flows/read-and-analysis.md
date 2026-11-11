# Reading and analysis

What happens when a page loads, and how payoff, spot and risk are produced.

## Loading positions: the fan-out

```mermaid
sequenceDiagram
    autonumber
    participant S as Web app
    participant C as PositionsController
    participant BS as BrokerService
    participant G as Each broker's gateway
    participant I as InstrumentService
    participant Cap as Capture (event)

    S->>C: GET /api/positions
    C->>BS: allPositions() for this user
    par one call per connected account
        BS->>G: getPositions(session)
        G-->>BS: neutral rows, or a failure
    end
    Note over BS: A failure becomes a warning on that connection.<br/>The other brokers' rows still arrive.
    BS->>I: resolve each row's underlying and contract
    BS-->>C: items + warnings
    BS--)Cap: PortfolioFetchedEvent
    Note over Cap: Archives the raw payload and the mapped rows
    C-->>S: 200 { items, warnings }
```

- **Partial success is the normal case and returns 200.** If Kite answers and Alice Blue's token is dead, the page
  gets Kite's rows plus a warning. A non-200 means the whole request failed.
- **Warnings have two kinds.** `SESSION_EXPIRED` means reconnect; `CALL_FAILED` is transient and must not tell the
  user to reconnect (a rate limit or a timeout is not an expired login).
- **Capture is decoupled.** The broker service publishes an event and knows nothing about the database, so no
  gateway call has a database side effect. A scheduled job also captures at 15:35 IST, and gaps are recorded, not
  hidden.
- **Instrument resolution** adds the underlying, strike, expiry and lot size from the contract master. Without it
  a four-leg condor would show as four groups of one, and no payoff could be drawn.

## Payoff

```mermaid
flowchart TD
    pos["Positions<br/>(one account)"] --> legs["Legs<br/>(strike, expiry, qty, entry price)"]
    inst["Contract master"] --> legs
    legs --> group["Group by account and underlying"]
    group --> engine["PayoffEngine<br/>201 samples + exact strikes,<br/>entry prices and spot"]
    spot["Spot price"] --> engine
    engine --> result["Curve, breakevens,<br/>max profit and loss,<br/>unlimited flags"]
    holdings["Holdings (optional)"] -.-> legs
```

The engine is a pure function: legs and a spot in, a curve out. Breakevens are found by linear interpolation
inside the plotted range and de-duplicated. Whether profit or loss is unlimited comes from the exact net call,
future or equity quantity at the upper tail. The curve always includes spot zero for the finite extremes.

### Where spot comes from

```mermaid
flowchart TD
    q["Need the spot for NIFTY"] --> own{"Does one of the user's own<br/>brokers quote it?"}
    own -- "yes: a quote" --> use["Use it, label the source"]
    own -- "no" --> chain{"Does the user have a broker<br/>that serves an option chain?"}
    chain -- "yes: the chain's own spot field" --> use
    chain -- "no" --> none["No spot: say so.<br/>Never invent one."]
```

The cache is **per user and per underlying**, with the source shown ("Current spot · Paytm"). An earlier shared
cache let one user's broker supply another user's price, which is why it is per user. A shared market-data
account for users without a quoting broker is designed but not built.

## The strategy builder

The builder posts a set of legs to `POST /api/payoff/simulate` or `/compare`. Existing positions import as an
**immutable baseline** per account and underlying; closes and additions are hypothetical draft trades on top.
Option prices come from the **option chain**, selected independently of the account that holds the positions (so
a Kite position can be priced from Alice Blue's chain). The chain is fetched through whichever of the user's
connections can serve it; Alice Blue is the only chain source today. The same source supplies the
builder's spot (the chain's own spot field, falling back to the payoff's spot only when it has none) and its
**futures** (`GET /api/market-data/futures`, the nearest three, each priced by its expiry's chain), so spot,
options and futures always agree. Draft legs are added from one "+ Add legs" sheet with an Options | Futures
switch.

## Risk

```mermaid
flowchart LR
    brokers["Brokers"] -- "positions, margins, spot" --> src["Live position and margin sources"]
    src --> risk["Risk service"]
    risk --> exp["Exposure"]
    risk --> bucket["Expiry buckets"]
    risk --> margin["Heuristic margin engine<br/>SPAN + exposure"]
```

**Risk is computed on the live book**
([ADR 0029](https://github.com/bnmnikhil/MoneyPlant/blob/main/docs/adr/0029-risk-inputs-are-live.md), which
supersedes 0012). `risk/` declares two inputs, `PositionSource` and `MarginSource`; their implementations in
`portfolio/` make the same broker calls the positions page makes, resolve each row through the contract master
and quote spot live, with no stored fallback. The calculators stay pure and never touch a broker (ArchUnit A2).
This is what the positions page's margin column reads, so it moves with the user's book. The cost: figures are
not reproducible from stored rows, and the call is repeated at the positions page's 30-second refresh.

## Where to read the code

| Topic | Start at |
|---|---|
| The fan-out | `broker/BrokerService.java` |
| A broker adapter | `broker/aliceblue/` (the most commented), or `broker/upstox/` (the newest) |
| Payoff | `analytics/PayoffEngine.java`, `PayoffService.java` |
| Spot | `marketdata/SpotPriceService.java` |
| Margin | `risk/HeuristicMarginEngine.java` |
| Capture | `snapshot/CaptureService.java` |
