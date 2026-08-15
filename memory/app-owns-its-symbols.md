---
name: app-owns-its-symbols
description: "MoneyPlant speaks its own instrument vocabulary end to end; the symbol-model doc's recommended middle path was overruled in favour of the full model"
metadata:
  type: decision
  decided: 2026-08-03
---

> **MoneyPlant speaks its own vocabulary end to end. Broker symbols exist only
> inside that broker's adapter, and only at the moment a call is made.**

**Why.** This is the anti-corruption rule already enforced for *types*, extended
to *names*. Names had leaked much further than types ever did, for a mechanical
reason: a broker SDK type fails to compile in the wrong package, but a `String`
passes through any signature without complaint. Nothing was stopping a
Kite-shaped symbol from reaching the UI.

**The overrule.** `tradestack/docs/symbol-model.md` recommends a middle path.
**It was overruled — the full model is the target.** The doc still reads as a
recommendation, so anyone following it without this memory will build the wrong
thing.

**Where it stands.** Step 1 (`UnderlyingRegistry` + `underlyings.properties`) is
shipped. Step 2 (`InstrumentKey`, `BrokerInstrument`) exists with tests but has
**no consumer outside `instrument/`**, and the DTOs still carry symbol strings.
Steps 3–4 — switching consumers over and closing the two remaining leaks — are
the real work and are untouched.

**Sequencing constraint:** the two leaks must be closed **together**, because
they change what the UI displays; closing one alone ships a half-renamed
interface. ADR 0019 makes this a hard prerequisite for the risk module.
