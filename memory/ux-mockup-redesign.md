# UX mockup redesign

Decision: 11 September 2026.

The owner selected the four PNGs in `UX mockup/` as the visual target and asked
for an exact match implemented one checkpoint at a time. `UX-REDESIGN.md` owns
checkpoint status, verification results, and resume instructions. This is the
current visual direction where it differs from the older `UX-STEP2.md` proposal.

The first checkpoint moves authenticated pages to a full-width frame with top
navigation: Overview, Positions, Holdings, Payoff, Risk. Broker settings and
connection actions remain available through header menus. Below 1024px, primary
navigation uses five bottom tabs. Navy/teal variables are scoped to the workspace
and its header menus, leaving the public landing/login theme intact.

The header's Live/Partial/Offline indicator describes broker sessions. It does
not certify quote or risk-data freshness; those remain page-level facts. The
broker count counts distinct broker providers, with accounts inside the dropdown.

Visual changes must preserve real calculation results and existing unavailable,
partial, mixed-expiry, holdings, and hypothetical-strategy semantics. The images'
example numbers are not application fixtures or a replacement for API data.

Overview follows the supplied five-metric strip and paired P&L/capital tables,
with collapsible account previews below. Combined capital remains a display
summary with an account-separation caption; utilisation uses the existing
`used / (available + used)` convention, not the inconsistent example percentages
in the image. A zero or invalid funding denominator has no percentage. Missing
data displays a dash or a marked partial total. Positions retain separate
since-entry and day P&L, and holding totals include pledged shares exactly once.

Positions follows `positions.png`: a five-part summary above a nine-column
table, with account and underlying folds, separate P&L/day columns and compact
premium figures. The first account and its first underlying open initially;
explicit expansion state survives polling. Mobile cards share the same folds
and retain the type-level premium breakdown. Account identity remains visible
even with a single account. Sticky headers sit at the top of the table's own
scroll container, avoiding the earlier viewport-offset clipping issue.

The headline counts nonzero-quantity positions while P&L includes all returned
rows, preserving realised P&L from closed positions. Estimated margin sums only
the risk groups matching displayed account/underlying keys; unrelated snapshot
groups cannot enter the headline. Its age remains visible. Account rows show
the actual broker bill; CE/PE and individual-leg margin remain blank because no
corresponding trustworthy figure is provided. Compact premium uses teal for both
credits and debits; the colour does not denote profit. Entry premium and ratios
move into tooltips, while incomplete-value markers remain visible.

Live payoff follows `payoff.png`: searchable curve selector with account identity,
five-metric summary, chart on the left and a scrolling five-column legs panel on
the right. Selection uses account/underlying keys, takes refreshed metadata and
clears on an empty curve list. Holdings choices remain scoped to that key. Adjust
strategy imports the displayed response and switching tabs preserves the draft.

Payoff metrics remain global API results, independent of chart zoom. Mixed expiry
curves retain scenario labels and all dates; incomplete-data warnings are visible.
Futures/shares have no strike placeholder, and leg quantities are signed units,
never multiplied by lot size. Holdings use the displayed response's included
quantity and purchase cost. T+0 is disabled. Chart presentation is opt-in: Live
uses a large chart; the builder uses a compact chart with expandable range controls.

Strategy builder follows `strategybuilder.png` with a context bar and separate
chain, legs and preview panels. Baseline import is behind Add existing / Change;
position account and quote source remain separate and visible. Session drafts
remain reachable after New strategy even if there is only one saved context.
Contract/price-source details expand within each draft instrument. Custom legs
select an actual chain contract and then allow manual price assumptions.

Baseline table P&L is explicitly unrealised at the imported mark; the response
does not supply realised P&L. A quantity is displayed as lots only when it is an
exact multiple; partial quantities and shares stay units. Draft cashflow excludes
disabled rows and is incomplete if an enabled price is missing. No sample capital
total is inferred from the mockup. Heuristic margin and premium remain separate.

Preview responses are paired with the input state that requested them. Changing
account, baseline or draft hides the previous result immediately until the new
calculation arrives. Cancelled requests cannot restore a prior result. This keeps
the graph, summary and editable legs consistent without changing payoff math or
automatically accepting new entry prices from a quote refresh.
