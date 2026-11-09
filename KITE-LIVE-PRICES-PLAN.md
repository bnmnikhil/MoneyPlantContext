# Kite live prices: implementation plan

Created 17 October 2026. Status: planned; no application changes or live-account verification.

## Outcome and scope

Use an entitled Kite Connect account as a market-data source for underlying spot prices,
live payoff marks and Strategy Builder option quotes. Keep portfolio quantities, entry costs,
realised P&L and broker margin bills authoritative to the account that holds the positions.
Prices may come from a different connection owned by the same user; positions remain account-local.

Recommended first release: batched REST quote snapshots using the existing page refresh cadence.
Streaming can follow once this path is certified. Historical data and storage are outside this task.

Confirmed by the owner on 17 October 2026: each user's own connected Kite account supplies
their prices. Quote sources must belong to the requesting user. No shared owner feed is included.

## Verified pricing change

The owner's notification corresponds to Zerodha's October 2026 Developer Credits offer:
paid Connect users generating at least Rs 2,000 brokerage in a calendar month receive
500 credits towards the following month's renewal. Connect is therefore effectively free
for eligible users, rather than an unconditional free data entitlement for every Personal app.
Do not attempt to infer eligibility from portfolio activity, switch subscriptions automatically,
or assume a connected account can quote. Verify the configured app's actual quote access.

Source, checked 17 October 2026:
[Zerodha signup and Developer Credits](https://support.zerodha.com/category/trading-and-markets/general-kite/kite-api/articles/how-do-i-sign-up-for-kite-connect).

## Current code and integration points

- `marketdata/SpotPriceService` discovers `SpotPriceProvider` implementations, then chain providers.
  It caches spot for five seconds per user/underlying; it has no Kite provider and no implemented
  admin feed. Its current cache also needs session-change invalidation.
- `marketdata/OptionChainService` discovers providers by broker, checks connection ownership,
  coalesces requests and caches by user, source connection and session generation. Alice Blue
  currently supplies the chain. Source discovery currently assumes that a provider bean means
  every connection of that broker is available; data entitlement requires a runtime status.
- `broker/kite/KiteHttp` is the existing stateless REST client and error mapper. Reuse its
  authentication and configurable endpoints; add properly encoded repeated query parameters.
- `KiteBrokerGateway` loads only the NFO derivative master. Its normalized `OptionInstrument`
  omits quote tokens, exchange and tick size. Spot instrument resolution needs NSE data too.
- `instrument/UnderlyingRegistry` owns canonical names; punctuation-stripped codes such as
  `MM` cannot be passed directly to Kite as stock symbols.
- `analytics/PayoffService` obtains spot through `SpotPriceService`, but current leg marks
  come from the position account. Adding spot alone will not refresh those option marks.
- Frontend chain polling is 15 seconds and position polling is 30 seconds. The builder already
  separates its quote source from the account whose positions it imports.
- The backend-owned Kite setup guide currently says Personal covers everything the app reads.
  It must distinguish portfolio access from Connect market-data access.

## Delivery sequence

### KQ-1 — Quote transport, resolution and entitlement

1. Add a `KiteQuoteClient` inside `broker/kite`, using `KiteHttp` and its existing endpoint settings.
   Use full `GET /quote` snapshots for timestamps, LTP and option OI; request only needed fields
   in the normalized result. Keep vendor JSON and authentication inside the adapter.
2. Build requests with repeated, URL-encoded `i=exchange:tradingsymbol` parameters. Chunk by both
   the documented 500-instrument limit and a conservative URL-size budget. Coalesce duplicate
   requests and share a quote limiter across spot, chain and mark consumers. Enforce at most
   one quote request per second per credential/quota scope; confirm the exact quota scope
   during certification, including registrations using the same API key. Bound queueing and
   return explicit unavailability when the request budget expires.
3. Add a daily Kite-local quote instrument catalogue for NSE and NFO, preserving exchange,
   exact symbol, token, lot size and tick size. Reuse existing daily-load locking/backoff where
   practical. Keep token-specific metadata adapter-local. Reject missing or ambiguous mappings.
   Test indices, ordinary stocks and punctuation-bearing stocks. Never use master-file
   `last_price` as a live quote or manufacture derivative symbols from expiry strings.
4. Probe one resolved quote lazily when market data is needed. Cache a connection's data-access
   result with a bounded retry/backoff and reset it on reconnect or credential replacement.
   Expose available, data access unavailable and transient failure separately. Classify the
   subscription/permission response from a real sample before depending on an error message.
   Only a genuine token error prompts reconnect; denied data access leaves portfolio access usable.

Acceptance: authenticated mock HTTP verifies query encoding and batching; missing keys, invalid
prices, access denial, token expiry, 429, timeout and malformed JSON produce distinct outcomes.
The owner's configured Connect app returns a real index and option quote in an explicit live check.

### KQ-2 — Kite spot provider and source policy

1. Implement `KiteSpotPriceProvider` using the quote client and canonical resolver.
2. Make automatic selection deterministic: own entitled Kite connections first, own Paytm next,
   own Alice Blue chain spot next, then unavailable. Within a broker sort by connection ID.
   Batch outstanding spot demand so loading multiple payoff curves cannot flood quote requests.
3. Carry provider, fetched time, exchange quote time and availability with spot. Do not label an
   old quote as current merely because it was fetched now; retain separate timestamps. Null or
   absent exchange timestamps remain unknown. Define stale thresholds in configuration and
   cover trading hours and closed-market last quotes explicitly in UI text.
4. Invalidate both successful and missing spot caches on disconnect, reconnect and credential
   changes; prevent data from an earlier session generation reappearing through in-flight work.
5. Keep fallback failures visible in diagnostics without logging credentials or raw account data.
   Missing spot continues to hide dependent calculations instead of inventing a reference price.

Acceptance: Kite-only users obtain spot; non-entitled users still get their portfolios and existing
fallbacks; source order, two-user isolation, session invalidation and concurrent demand are tested.

### KQ-3 — Builder chain assembled from Kite contracts

1. Implement `KiteOptionChainProvider`. Discover non-expired expiries and actual strikes from
   the NFO master, select strikes around the current spot, then fetch the selected CE/PE symbols
   through the shared quote client. Preserve real strike gaps and one-sided/missing contracts.
2. Return existing neutral provider records: spot, per-side LTP/known flag/OI, contract lot size,
   tick size and quote time. Review per-instrument timestamp support: the current provider record
   has only one snapshot timestamp, so extend observations if a batch contains differing times;
   never imply all quotes were simultaneous. Treat missing values distinctly from numeric zero.
3. Add runtime data-access status to source discovery. Prefer an entitled position connection,
   then another entitled own Kite connection, then Alice Blue. Preserve an explicit user source
   selection. A selected source failure is shown with an available alternative rather than silently
   switching sources and relabelling quotes. Automatic selection can try the next eligible source.
4. Retain existing canonical contract matching, lot-size conflict checks, request coalescing and
   stale response handling. Set a bounded stale lifetime; expired auth/access cannot keep serving
   an indefinitely cached chain. Availability must reflect whether usable observations exist.

Acceptance: a Kite-only user can select expiry, see both option sides, load a template and obtain
a simulation using actual quotes. Test nonuniform strikes, missing sides/OI, lot changes,
punctuation, multiple expiries, stale observations and unauthorized source IDs.

### KQ-4 — Live payoff marks and frontend integration

1. Introduce a broker-neutral contract quote boundary for existing payoff legs. Resolve a held
   option/future/equity to an exact Kite contract and batch marks with the same client. Keep
   quote provenance separate from position ownership. Define fallback explicitly: fresh Kite,
   otherwise a known position-account mark with its own provenance/time, otherwise unavailable.
2. Feed these marks to live payoff projections and builder imports that consume current marks.
   Preserve imported signed position bases and user-entered hypothetical entry prices: refreshing
   a market mark must never change an entry cost or rewrite the user's draft.
3. Add source, time and unavailable/stale messages where prices are consumed. Update backend
   response DTOs and `src/types/api.ts` together; types are currently maintained manually.
   Refresh/invalidate frontend quote queries when connection state or selected source changes.
4. Update the broker setup guide: Personal remains sufficient for portfolio reads; market quotes
   require active Connect access and may be covered by Developer Credits. Explain access denial
   without sending users through repeated reconnects. Keep existing 15/30-second polling initially.
5. Portfolio tables continue to show the source broker's reported P&L and marks in this release.
   Replacing all brokers' table prices or recalculating their P&L is a separate financial-data change.

Acceptance: an account at another broker can use the same user's Kite quotes for payoff/builder
without moving positions, changing P&L or merging accounts. Missing marks disable dependent
projections. Quote refresh preserves draft prices, quantities and baseline costs.

### KQ-5 — Certification and staged rollout

- Extend the separate `broker-sim` repository with quote fixtures and entitlement/error profiles.
  It is absent from this checkout; obtain that repository before simulator work. Production
  endpoint guards remain effective; staging must never call the live Kite API.
- Add regression tests at the HTTP, provider, source-selection, financial-consumer and frontend
  boundaries. Use fixed clocks and synthetic fixtures. Cover concurrent spot/chain demand,
  rate limits, access loss, disconnect races, closed markets and two-user isolation.
- Run backend `.\mvnw.cmd clean test`; frontend `npm test` and `npm run build`. The current
  context verifier expects the old nested repository layout, so use direct commands here.
- Verify desktop and phone: Kite-only, other-broker positions with own Kite data, Personal-only,
  expired session, partial quotes, unavailable data, stale data and rapid underlying/expiry changes.
- Certify live during market hours against the owner's Kite terminal: NIFTY/BANKNIFTY, one ordinary
  stock, one punctuation-bearing stock, option CE/PE and one future. Compare exact symbols,
  timestamps, LTP, OI and lot sizes; capture redacted observations, never tokens or portfolio dumps.
- Ship behind `GB_KITE_MARKET_DATA` (proposed, default off), covering provider discovery and all
  Kite quote consumers. Enable after certification; monitor quote latency, 429s, access failures,
  cache hit rate and fallback counts. Disable the flag to restore existing providers. Bypass any
  cached Kite results when disabled. Merge/deployment remain separate requested actions.

Done means spot, chain and payoff marks work with only an entitled Kite connection; existing
providers still work without it; no cross-user data leakage occurs; stale/missing prices are
visible; and all tests plus the live comparison have passed.

## Later: streaming

After snapshot certification, consider a backend-managed Kite WebSocket with subscription demand
tracking, reconnect/backoff, resubscription and restart recovery, feeding the same quote boundary.
Browser updates would need authenticated delivery (for example SSE) and explicit stale-state handling.
Keep credentials server-side. Measure whether 15/30-second snapshots are insufficient before adding
this lifecycle; do not describe REST polling as tick streaming.

## Technical references

- [Market quotes and instruments](https://kite.trade/docs/connect/v3/market-quotes/): quote endpoint,
  batch shape, missing-key behavior and instrument metadata.
- [Errors and rate limits](https://kite.trade/docs/connect/v3/exceptions/): quote budget and token errors.
- [WebSocket protocol](https://kite.trade/docs/connect/v3/websocket/): later streaming transport.
- Existing decisions: `memory/quote-source-is-independent-of-position-account.md`,
  `memory/no-cross-broker-merging.md`, `memory/shared-market-data-fallback.md`,
  `memory/an-unmeasured-zero-is-a-claim.md` and `TESTING.md`.
