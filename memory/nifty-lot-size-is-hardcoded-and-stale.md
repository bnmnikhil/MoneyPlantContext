---
name: nifty-lot-size-is-hardcoded-and-stale
description: "The strategy builder hardcodes NIFTY lot size 75; two independent Alice Blue sources say 65, so every NIFTY leg is sized 15% too large"
metadata:
  type: state
---

Found 18 Aug 2026 while verifying [[aliceblue-option-chain-verified]].

`PayoffService.getStrategyMetadata` hardcodes NIFTY's lot size as **75**, and
`StrategySimulationTest` asserts it. **Two independent Alice Blue sources say
65** — the live option chain's `lotsize` field, and the NFO contract master via
`/api/debug/instrument?brokerId=aliceblue&symbol=NIFTY25AUG26C24200`.

**This is a live bug, not a tidiness issue.** Lot size multiplies every leg, so
the strategy builder sizes every NIFTY position 15% too large and margin, max
profit, max loss and total capital all inherit the error. It compounds with the
invented premiums recorded in [[strategy-builder-architecture]]: the margin
engine is calibrated to ~4% against a real Zerodha bill and is being handed both
a wrong quantity and a guessed price.

**Fix it by reading the contract master, not by editing 75 to 65.** The exchange
revises lot sizes; a corrected literal is a literal that goes stale again, and
the next reader has no way to know it was ever checked. `InstrumentService`
already loads the real value per broker, and the chain returns it per call — the
same fetch that fixes the premiums fixes this for free. Editing the number and
its test would look like a fix while leaving the mechanism that produced the bug
in place.

The wider point is in [[app-owns-its-symbols]]: contract facts belong to the
instrument model, and every hardcoded copy of one is a future disagreement. The
same file also hardcodes strike steps, default spots, and an expiry list built
from the next four Thursdays in the system default zone — none of which survive
contact with a real contract master either.
