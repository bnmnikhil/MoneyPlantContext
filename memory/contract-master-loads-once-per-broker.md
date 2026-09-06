# The contract master loads once per broker, behind its own lock

**Decided 6 Sep 2026** (P0 item B1, `tradestack` commit `66ad28c`).

`InstrumentService.ensureLoaded` was `synchronized` on the singleton *and* called
once per position row. Either alone is survivable; together they meant a 40-row
book made 40 attempts, each paying the broker's full connect timeout while
holding a monitor every other broker's load also needed — so **one user's slow
broker stalled every other user's request, for every broker.** That is the whole
of why this was one of the two findings that outranked the original P0 checklist.

## What was chosen

- **A lock per broker, not per service.** Two brokers load concurrently; only a
  second load of the *same* broker waits, which is the wait that saves work.
- **The fast path reads `loadedOn` without the lock.** This is what makes the
  common case free, and it is safe only because of write ordering: `load`
  publishes the two index maps *first* and `loadedOn` *last*, all through
  `ConcurrentHashMap`, so a thread seeing today's date has necessarily seen the
  maps that go with it. **Reordering those three writes reintroduces a
  visibility bug that no test here will catch.**
- **A 60s negative cache on failure**, so a broken master cannot be retried in a
  tight loop.
- **The refusal throws rather than returning.** `InstrumentMasterUnavailableException`
  exists because returning normally would leave the caller's `find` empty, and an
  empty `find` reads as *"the master does not list this symbol"* — a far more
  confident claim than *"the master never loaded"*. This is the same rule as
  `priceKnown` and `MarginBasis.UNAVAILABLE`: see [[an-unmeasured-zero-is-a-claim]].
  Every existing caller already caught `RuntimeException`, so nothing needed to
  change to accommodate it.

## What was rejected

- **Leaving the load inside `resolveInstrument` and relying on the negative cache
  alone.** It would bound the attempt count, but the log line stays per row and
  the first failure of each request still runs under the lock. Hoisting also
  makes the honest statement possible: a miss in the row loop now genuinely means
  "not in the master".
- **Deduplicating by connection rather than by broker.** The cache is keyed by
  broker, so two Kite accounts must share one attempt and one log line.

## What is still unproven

`aSlowBrokerDoesNotBlockAnotherBrokersLoad` was run against the old
`synchronized` method and fails there, so the headline claim is measured. But no
test exercises **two users**, which is what B1's stated browser verification is
for and why the item is `[~]`. See also [[step-4-landed-as-one-commit]] for the
project's habit of trusting a plan's acceptance criteria over a measurement.
