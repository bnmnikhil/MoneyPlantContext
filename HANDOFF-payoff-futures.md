# Futures payoff investigation

**Historical handoff.** Superseded for current status by `P0-LAUNCH.md` and
`memory/payoff-ranges-and-limits.md` (9 Sep 2026). Off-screen breakevens and
interactive chart ranges are now implemented; native Chrome verification works.
The results and process IDs below describe the original 6 Sep investigation only.

## Task and access

The user reported an incorrect payoff graph when a future is present and asked
whether their logged-in Chrome tab was visible. Browser skill bootstrap succeeded
but `iab` was unavailable and browser discovery returned no sessions. Chrome was
not inspected. No browser-authentication workaround or token extraction was used.

The already-running local development API is accessible at
http://127.0.0.1:5173/api through Vite. Its normal dev identity now has connected
Kite and Paytm accounts. The user was asked whether they were using localhost or
production and which underlying was affected; no answer was needed to reproduce
the issue from the local live response.

## Reproduction

Observed NIFTY legs: long 65 of the 23,850 put, entry 41.84, expiry 8 Sep 2026;
long 65 October futures, entry 24,507.93, expiry 27 Oct 2026. Spot 23,897.70.

Original graph range: 0 to 38,160. Futures' placeholder strike zero set the lower
anchor. Futures-only graphs collapsed to a single spot. The NIFTY curve also
reported unlimited loss because cancellation noise on its flat downside was
treated as a nonzero tail slope. The live AUBANK iron condor incorrectly reported
both limits unlimited, and the ITC put spread reported unlimited profit.

## Local changes

- Backend `PayoffEngine`: anchors on option strikes, futures/equity entry prices
  and current spot; includes exact corners; ignores closed legs; rounds P&L;
  deduplicates breakevens; computes unlimited tails from exact signed units;
  evaluates finite extrema at zero as well as all chart points.
- `PayoffService`: passes current spot in both live and simulated paths.
- Backend tests: engine coverage for real affected leg values, long/short futures,
  covered futures, put bounds, butterflies, offsets and closed positions; service
  tests for live mapping, expiry preservation and spot propagation.
- Frontend: linear payoff segments; mixed-expiry scenario title, dates, explanatory
  note and qualified limit cards. It does not model later contracts at first expiry.
- Project context and `memory/payoff-ranges-and-limits.md` updated.

Earlier premium changes remain intact and uncommitted. No deployment, push,
commit, account changes or orders were made. No agents were spawned.

## Verification checkpoint

Original engine with regression tests: 10 tests, 8 failures, 0 errors. Final
`mvn -B clean test`: **405 tests, 0 failures/errors/skips, BUILD SUCCESS**, 6 Sep
2026 22:14 IST. The first full run had one overly tight new viewport assertion
(18,948 was below the asserted 19,000); corrected the assertion to an appropriate
18,000 bound. No production calculation changed for that correction.

Frontend `npm run build` passed TypeScript and Vite (existing large-chunk warning).
`npm test`: all 8 premium regression tests passed. Diff whitespace checks passed.

The local backend was restarted and serves the fix on 127.0.0.1:8080, Java PID
8808, exec session 27095. It restored 3 broker sessions (Alice Blue, Kite, Paytm).
Frontend remains at http://localhost:5173/app/payoff. Installed `mvn` works;
the wrapper previously failed. Server log: `tradestack/target/payoff-server.log`.

Live API verification after restart independently calculated every point using
decimal arithmetic: all **614 points across 3 curves** matched within a paisa.
Sanitized summary is in `tradestack/target/payoff-live-verification.json`:

- Paytm NIFTY: range 18,948.414–29,409.516; breakeven 24,549.77; combined-scenario
  maximum loss -45,485.05; unlimited profit true, unlimited loss false. This
  retains both original expiry dates and is explicitly qualified in the UI.
- Kite AUBANK: max profit 7,900; max loss -32,100; both unlimited flags false.
- Kite ITC: max profit 1,811.25; max loss -6,813.75; both unlimited flags false.

No outstanding implementation or check remains for this scoped correction.

No visual browser verification is possible without a connected browser session.
Breakevens outside the plotted range and full valuation across expiries remain
outside this fix.
