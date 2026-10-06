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
connections can serve it; Alice Blue is the only chain source today.

## Risk

```mermaid
flowchart LR
    brokers["Brokers"] -- "every fetch" --> cap["Capture"]
    cap --> snap[("Snapshot tables")]
    snap --> risk["Risk service"]
    risk --> exp["Exposure"]
    risk --> bucket["Expiry buckets"]
    risk --> margin["Heuristic margin engine<br/>SPAN + exposure"]
```

**The risk module reads stored snapshots, never brokers**
([ADR 0012](https://github.com/bnmnikhil/MoneyPlant/blob/main/docs/adr/0012-risk-reads-snapshots-never-brokers.md)).
That keeps a risk request from depending on a live session or on market hours. The cost is that the figures are
only as fresh as the last capture, and the page says which. **Known problem:** the snapshot tables were seeded
once and are not refreshed from the archive, so the risk page can compute on positions days old (launch item A1).
The numbers are labelled `STALE`, but they are wrong until A1 is fixed.

## Where to read the code

| Topic | Start at |
|---|---|
| The fan-out | `broker/BrokerService.java` |
| A broker adapter | `broker/aliceblue/` (the most commented), or `broker/upstox/` (the newest) |
| Payoff | `analytics/PayoffEngine.java`, `PayoffService.java` |
| Spot | `marketdata/SpotPriceService.java` |
| Margin | `risk/HeuristicMarginEngine.java` |
| Capture | `snapshot/CaptureService.java` |
