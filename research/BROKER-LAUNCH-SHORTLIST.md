# Broker launch shortlist

**Researched:** 21 September 2026
**Status:** Provisional launch shortlist; API portal checks and terms review remain
before implementation commitment.
**Scope:** Ten brokers in total, including the existing Zerodha, Paytm Money and
Alice Blue integrations.

> **Follow-on decision:** New integrations must pass a stricter no-static-IP
> eligibility gate for app activation, positions and holdings. The reach-first
> list below is retained as the research baseline; the executable roster and
> delivery sequence are now defined in
> [`BROKER-EXPANSION-PLAN.md`](../BROKER-EXPANSION-PLAN.md).

This is a dated research snapshot, not code-truth. Broker portals, prices and API
rules can change without notice. Re-check every selected broker before its
implementation starts.

## Decision

Use the latest available NSE active-client count as the reach baseline. Keep the
three existing integrations and add these seven brokers:

1. Groww
2. Angel One
3. ICICI Direct
4. Upstox
5. Kotak Neo
6. HDFC Securities / HDFC Sky
7. Dhan

This is a **reach-first shortlist**, not an assertion that all seven are ready to
implement. Upstox and Kotak Neo are the cleanest first pilots. Groww needs a small
real-account or support-confirmed read-only test, while Dhan needs partner-model
confirmation. Angel One, ICICI Direct and HDFC currently appear to require
static-IP information during app or API-key activation and therefore remain
conditional.

If MoneyPlant makes no-static-IP app creation a hard launch requirement, replace
the three conditional additions, in reach order, with Motilal Oswal, 5paisa and
FYERS.

## Ranking method

The ranking source is NSE's
[Report 1C workbook](https://nsearchives.nseindia.com/miscellaneous/ArbitrationReports/isc_report1C_2627.xls),
using the `NO. OF ACTIVE CLIENTS` column for the snapshot ending 31 August 2026.
The report total is 45,961,187.

Counts are broker-level active-client records, not unique people: one person with
accounts at two brokers can be counted twice. The measure is a useful proxy for
integration reach, not market share of unique investors or MoneyPlant's expected
user mix.

The fixed three plus the seven additions account for 35,619,715 records, or
77.50% of the NSE total.

## Proposed ten

| Broker | Status | NSE rank | Active clients | Positions and holdings | Static IP at app/key setup | Read-only source-IP restriction | Implementation gate |
|---|---|---:|---:|---|---|---|---|
| Groww | Add | 1 | 13,347,233 | Both documented | Appears optional and added separately | Official guidance scopes static IP to orders, but does not explicitly promise portfolio access without it | Confirm with a data-only app |
| Zerodha / Kite | Existing | 2 | 6,796,854 | Both documented | Not required for read-only use | Positions, orderbook and WebSocket remain available from any IP | Retain |
| Angel One | Add, conditional | 3 | 6,718,755 | Both documented | Current Add App guidance asks for a static IP | Non-order and non-GTT APIs are documented as not requiring static IP | Verify whether a data-only app can be created without the field |
| ICICI Direct / Breeze | Add, conditional | 4 | 2,156,209 | Both documented | Documentation says IP is registered while procuring the API key | Enforcement language is scoped to orders | Portal-check; accept setup friction or replace |
| Upstox | Add | 5 | 1,864,628 | Both documented | Not required for a standard OAuth data-only app | Standard holdings and positions are explicitly outside static-IP restrictions | Use standard OAuth, not the one-year Analytics Token |
| Kotak Neo | Add | 6 | 1,391,663 | Both documented | App can be created before an IP is added | Login, reports, portfolio, data and WebSocket APIs are outside IP validation | Preferred pilot |
| HDFC Securities / HDFC Sky | Add, conditional | 7 | 1,351,311 | Both advertised | Required; the app remains deactivated until an IP is mapped | Not enough evidence of a separate no-IP data-only app | Accept setup friction or replace |
| Dhan | Add | 8 | 1,107,277 | Both documented | Static IP is an optional setting until order placement is used | Official API reference scopes IP to order placement | Verify the partner onboarding model |
| Paytm Money | Existing | 11 | 790,743 | Both documented | Required in the portal based on current project observation | Public documentation is not clear enough | Retain; capture redacted portal evidence |
| Alice Blue | Existing | 34 | 95,042 | Both documented | Required in the portal based on current project observation | Public documentation is not clear enough | Retain; capture redacted portal evidence |

### What the static-IP columns mean

These questions are intentionally separate:

1. Can the user create and activate an app or API key without supplying a static
   IP?
2. Can MoneyPlant fetch positions and holdings from a changing source IP?
3. Are order endpoints restricted to a whitelisted static IP?

The third answer is generally yes under the current retail-algo framework, but
MoneyPlant is read-only. It does not settle the first two questions. Actual
developer portals can also impose fields that the public documentation omits.

## Broker evidence

### Groww

- [Portfolio API](https://groww.in/trade-api/docs/curl/portfolio) documents
  holdings and positions.
- [Static-IP setup](https://groww.in/blog/static-ip-api-trading-setup) describes
  the IP as an order-placement control added through the API Keys page.
- [API page](https://groww.in/trade-api) currently lists a price of ₹499 plus tax
  per month. Re-check pricing before implementation.
- Confidence: medium-high. The public material strongly implies no IP is needed
  for read-only calls, but does not state that exemption in one unambiguous
  sentence.

### Zerodha / Kite

- [Kite static-IP support article](https://support.zerodha.com/category/trading-and-markets/general-kite/kite-api/articles/static-ip)
  says IP restrictions apply only to order placement; orderbook, positions and
  WebSocket access continue from any IP.
- Confidence: high.

### Angel One

- [SmartAPI documentation](https://smartapi.angelone.in/docs) documents holding
  and position endpoints.
- [Exchange-regulation setup](https://smartapi.angelone.in/exchange-regulations)
  instructs users to enter a static IP while adding an app.
- Angel's official developer forum states that static IP is not mandatory for
  APIs other than Orders and GTT, but that does not remove the current app-form
  friction.
- Confidence: high on API capability; medium-high on the creation blocker until
  the portal is observed with a new data-only app.

### ICICI Direct / Breeze

- [Breeze API reference](https://api.icicidirect.com/breezeapi/documents/index.html)
  documents portfolio holdings and positions.
- The same reference says orders must originate from the static IP registered
  while procuring the API key.
- Confidence: high that the endpoints exist and that orders are restricted;
  portal verification is required to determine whether the IP field can be
  omitted for a read-only key.

### Upstox

- [Holdings](https://upstox.com/developer/api-documentation/get-holdings/) and
  [positions](https://upstox.com/developer/api-documentation/get-positions/) are
  documented separately.
- [Algo-trading update](https://upstox.com/developer/api-documentation/announcements/algo-trading-circular/)
  explicitly excludes standard holdings, positions, funds and historical-data
  APIs from static-IP restriction.
- The long-lived Analytics Token is a different product and does require static
  IP for account-specific portfolio access. MoneyPlant should use the normal
  OAuth flow.
- Confidence: high.

### Kotak Neo

- The [official Python SDK](https://github.com/Kotak-Neo/kotak-neo-python)
  supports holdings and positions.
- [Static-IP details](https://www.kotakneo.com/platform/kotak-neo-trade-api/static-ip-details/)
  exclude login, report, portfolio, data and WebSocket APIs from IP validation,
  and show IP addition as a step after application creation.
- Confidence: high.

### HDFC Securities / HDFC Sky

- The [developer portal](https://developer.hdfcsky.com/) advertises positions
  and holdings APIs.
- HDFC's [algo-safety update](https://hdfcsky.com/blogs/share-market/safer-participation-in-algorithmic-trading)
  says every API key requires a dedicated static IP and the app stays deactivated
  until the IP is mapped.
- Confidence: high that strict no-IP app creation currently fails.

### Dhan

- [Portfolio documentation](https://dhanhq.co/docs/v2/portfolio/) covers both
  holdings and positions.
- [Authentication documentation](https://dhanhq.co/docs/v2/authentication/)
  limits static-IP requirements to order-placement APIs.
- MoneyPlant's hosted multi-user model may require Dhan partner onboarding rather
  than individual trading-app credentials.
- Confidence: high for an individual's read-only API behavior; medium for the
  applicable hosted partner model until Dhan confirms it in writing.

### Paytm Money and Alice Blue

- [Paytm Money developer portal](https://developer.paytmmoney.com/) and
  [Alice Blue portfolio documentation](https://ant.aliceblueonline.com/productdocumentation/portfolio/)
  document portfolio access.
- The static-IP-at-creation findings currently come from project observations of
  the live portals. Capture redacted, dated evidence and seek written support
  confirmation before publishing these as user-facing claims.
- Confidence: high enough for internal planning, not yet for public copy.

## Reserves and exclusions

| Candidate | NSE rank / clients | Decision | Reason |
|---|---:|---|---|
| SBI Securities | 9 / 1,043,820 | Defer | No current public, self-service retail portfolio API or developer reference was found |
| Motilal Oswal | 10 / 906,005 | Reserve 1 | Holdings and positions are documented; the [FAQ](https://invest.motilaloswal.com/moAPI/APIDocumentation/FAQ) scopes static IP to order placement, but app-creation and read-only behavior need confirmation |
| 5paisa | 16 / 321,573 | Reserve 2 | [Holdings](https://xstream.5paisa.com/dev-docs/portfolio-management-system/holdings) and [positions](https://xstream.5paisa.com/dev-docs/portfolio-management-system/netwise-positions) exist; official guidance scopes IP enforcement to order placement, but the dashboard asks users to submit an IP against the key |
| FYERS | 21 / 196,429 | Reserve 3 | Strongest no-IP fallback: [FYERS support](https://support.fyers.in/portal/en/kb/articles/how-do-i-activate-the-new-app-for-api-trading-after-april-1-2026) explicitly leaves existing apps in data-only mode for positions and holdings without trading activation |

## Gates before implementation

- Create a new data-only app in each selected portal and record whether the
  static-IP field is absent, optional or mandatory.
- Fetch empty and non-empty holdings and positions from a non-whitelisted IP.
- Confirm token lifetime, daily login, callback rules, price and rate limits.
- Confirm that MoneyPlant's hosted multi-user use is allowed; retail APIs meant
  only for an account owner's personal scripts may require partner onboarding.
- Review display, retention, caching, branding and redistribution terms.
- Store only redacted observations and synthetic fixtures; never archive user
  credentials or raw personal portfolio responses.

Only after these gates should a broker move from `provisional` to `integrate` in
the implementation backlog or appear as supported on the landing page.
