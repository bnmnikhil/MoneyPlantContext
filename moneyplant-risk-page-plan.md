# Moneyplant risk page — analysis and mathematical models

Date: 15 October 2026  
Status: Proposed product and modelling plan  
Scope: Multi-broker equities, futures, and options portfolios.

## Purpose

Help users answer three questions:

1. What can hurt my portfolio?
2. How much could I lose?
3. Which account could run short of funds?

Start with scenario analysis, Greeks, and account-level margin pressure. Introduce statistical loss models once reliable historical data is available.

## Proposed analyses

| Analysis | User-facing output | Mathematical approach | Priority |
|---|---|---|---|
| Market sensitivity | Estimated impact of a 1% underlying move, rising volatility, and one day passing | Delta, gamma, vega, theta | First release |
| Stress testing | Portfolio P&L under falls, rallies, volatility spikes, and overnight gaps | Full instrument repricing | First release |
| Margin pressure | Available funds, utilisation, and estimated stressed shortfall per account | Broker margins and scenario estimates | First release |
| Expiry risk | Upcoming expiries, hedge legs expiring first, and settlement obligations | Contract rules and expiry payoff analysis | First release |
| Concentration | Biggest sources of directional, volatility, and downside risk | Exposure weights and scenario contributions | First release |
| Tail loss | One-day loss threshold and average loss in the worst scenarios | Historical VaR and Expected Shortfall | Second release |
| Diversification | Correlated exposures and holdings that move together | Covariance, correlation, factor regression | Second release |
| Liquidity risk | Estimated closing cost and instruments with poor quotes | Bid–ask spreads, depth, slippage scenarios | Second release |
| Risk history | Changes in exposure, drawdown, margin pressure, and limits | Portfolio snapshots and cash-flow-adjusted returns | Second release |

## 1. Shared pricing engine

Use Black–Scholes–Merton with appropriate dividend/carry assumptions, or its forward-based formulation, for European options. Derive implied volatility from market quotes and use it to calculate theoretical prices and Greeks.

Each contract must retain its own:

- Underlying and instrument identifier.
- Strike and option type.
- Expiry and exact remaining time.
- Lot size, signed position quantity, and account.
- Market mark, quote timestamp, and source.
- Implied volatility and relevant rate/dividend assumptions.

A single IV for all options on an underlying misses volatility skew. Introduce strike- and expiry-dependent IV inputs as quote coverage permits.

Prefer valid bid–ask midpoints for analytical marks. Flag wide spreads, stale quotes, and failed IV calculations. Missing inputs must produce an unavailable estimate rather than a zero-risk result.

Source: [Cboe theoretical options and implied volatility methodology](https://cdn.cboe.com/api/global/us_indices/governance/Cboe_European-Style_Option_%20Implied_Volatility_Calculation_%20Methodology.pdf).

## 2. Greeks and immediate sensitivities

Translate Greeks into amounts users can interpret:

| Greek | Display |
|---|---|
| Delta | Estimated rupee impact of a 1% underlying move |
| Gamma | Change in directional sensitivity as the underlying moves |
| Vega | Estimated rupee impact of a one-percentage-point increase in IV |
| Theta | Estimated impact of one day passing, other inputs unchanged |

For small changes:

$$
\Delta V \approx \sum_i q_i\left[
\delta_i\Delta S_i+
\frac{1}{2}\gamma_i(\Delta S_i)^2+
\nu_i\Delta\sigma_i+
\theta_i\Delta t
\right]
$$

Where:

- `q_i` is signed quantity in underlying units; apply the contract multiplier exactly once.
- `delta_i`, `gamma_i`, `nu_i`, and `theta_i` are per-unit model sensitivities.
- Volatility and time changes must use the units expected by the model.
- Convert model outputs explicitly into rupees per 1% price move, per one IV percentage point, and per day.

Aggregate by underlying and expiry first. Raw deltas for unrelated underlyings should not be presented as one meaningful exposure. Rupee sensitivities are more interpretable.

Greeks describe local sensitivity and change with market conditions.

Source: [Options Industry Council — understanding options Greeks](https://prd-web.optionseducation.org/advancedconcepts/understanding-options-greeks).

## 3. Full-repricing stress engine

Make scenario analysis the main interactive risk view.

### Suggested controls

- Underlying movement: −10%, −5%, −2%, 0%, +2%, +5%, +10%.
- IV movement: −5, 0, +5, +10 percentage points.
- Horizon: now, next trading day, or a selected date.
- Scope: whole portfolio, broker account, underlying, or expiry.

These are starting scenario choices, not calibrated probabilities.

For each scenario:

$$
\text{Scenario P\&L}=
\sum_i q_i\left(P_i^{\text{scenario}}-P_i^{\text{current}}\right)
$$

Reprice each option using its own remaining time to expiry. Include settlement cash flows when the scenario crosses an expiry, with appropriate treatment of physically settled positions.

Show:

- Portfolio P&L heatmap.
- Loss by broker account.
- Loss by underlying and instrument.
- Largest loss contributors.
- Changes in directional and volatility exposures.
- Estimated funding pressure, where sufficient margin inputs exist.

Named scenarios can include:

- Market fall plus volatility spike.
- Market rally against short calls.
- Overnight gap.
- Volatility crush.
- Time passing with the underlying unchanged.
- Protective hedge removed or expired.

Use full repricing for large shocks and near-expiry positions. Keep loss from current marks separate from P&L since entry.

## 4. Exact expiry payoff and hedge analysis

For legs sharing an underlying and expiry, combine their payoff functions before calculating maximum profit and loss.

Vanilla-option expiry payoff is piecewise linear. Evaluate the combined portfolio at strike boundaries and inspect its tails to identify bounded or unbounded outcomes.

Outputs:

- Maximum profit and loss.
- Breakevens.
- Hedge effectiveness.
- Exposure after removing a protective leg.
- Exposure when a hedge expires before the position it protects.

Do not sum standalone contract maximum losses to describe a spread.

For mixed expiries, use dated scenarios and explain assumptions. One terminal curve does not capture every possible price path.

### Settlement readiness

Include cash required, shares required, and available deliverable holdings for physically settled stock derivatives. Read settlement rules from current contract metadata; do not infer them from symbol formatting.

NSE stock options are European-style and physically settled.

Source: [NSE — individual securities F&O contract specifications](https://www.nseindia.com/static/products-services/equity-derivatives-individual-securities).

## 5. Historical VaR and Expected Shortfall

Start with historical simulation using full repricing:

1. Collect aligned historical underlying returns and volatility changes.
2. Apply each historical shock jointly to today's portfolio.
3. Reprice the current positions.
4. Build the simulated loss distribution.

At 95% confidence:

- **VaR:** the loss threshold exceeded in approximately 5% of model scenarios.
- **Expected Shortfall:** the average loss across the worst 5% of model scenarios, using a documented tail-estimation convention.

VaR is not maximum possible loss. Expected Shortfall describes the severity of losses beyond the threshold.

Start with one-day 95% results. Add 99% only when the history supports it: with 500 observations, the worst 1% contains only about five observations.

Display:

- Confidence level.
- Horizon.
- Historical window and sample size.
- Model and marking assumptions.
- Data coverage and missing risk factors.
- Calculation timestamp.

Expected Shortfall is also used in the Basel market-risk framework; this product proposal does not claim regulatory-model compliance.

Source: [BIS — minimum capital requirements for market risk](https://www.bis.org/publications/201901-standards-minimum-capital-requirements-market-risk).

## 6. Volatility, correlation, and simulation models

| Model | Suitable use | Main limitation |
|---|---|---|
| Rolling covariance | Basic diversification and equity portfolio volatility | Reacts slowly to changing conditions |
| EWMA covariance | Give recent market moves more weight | Decay parameter needs validation |
| GARCH(1,1) | Forecast time-varying volatility | Requires calibration and monitoring |
| Factor regression | Explain market and sector exposure | Relationships can change |
| Correlated Monte Carlo | Generate joint price and volatility scenarios | Depends heavily on distribution assumptions |

### EWMA covariance

With a zero-mean return assumption:

$$
\Sigma_t=\lambda\Sigma_{t-1}
+(1-\lambda)r_{t-1}r_{t-1}^{T}
$$

Here, `Sigma_t` is the covariance estimate, `r` is the aligned return vector, and `lambda` controls decay.

EWMA is a practical next step after rolling estimates. Choose and validate the decay parameter instead of treating a conventional value as universally correct.

### GARCH

GARCH(1,1) models changing conditional variance:

$$
\sigma_t^2=\omega+\alpha\epsilon_{t-1}^2+\beta\sigma_{t-1}^2
$$

Fit and validate parameters on suitable return histories. A univariate GARCH forecast alone does not supply the portfolio's joint dependence model.

### Factor regression

Estimate how holdings respond to selected market and sector factors. Use the results to explain common drivers and overlapping exposures.

Keep residual/idiosyncratic risk visible. For options, account for nonlinear responses rather than relying only on a linear factor approximation.

### Monte Carlo

Generate correlated risk-factor scenarios and fully reprice the portfolio. Add only after the simpler models are working and validated.

For real-world loss probabilities, calibrate real-world risk-factor dynamics. Risk-neutral option-pricing probabilities must not be presented as real-world probabilities of profit.

Sources:

- [MSCI — RiskMetrics technical document](https://www.msci.com/research-and-insights/paper/1996-riskmetrics-technical-document).
- [Robert Engle — Nobel lecture on risk and volatility](https://www.nobelprize.org/uploads/2018/06/engle-lecture.pdf).

## 7. Margin and account funding

Display broker-reported margin separately from model estimates.

NSE Clearing uses portfolio-based SPAN margining. A fixed percentage of notional cannot reproduce it. Estimates require current risk parameters and applicable charges.

For each broker account show:

- Reported margin used and available funds, with broker field definitions.
- Cash versus collateral and any known eligibility constraints.
- Estimated margin under selected stress scenarios.
- Potential funding shortfall.
- Data freshness and estimate coverage.

Economic hedges across brokers can reduce combined market exposure, while collateral and funding remain separate. Do not imply that a surplus in one account automatically covers another account's shortfall.

Document the funding calculation carefully: avoid counting the same loss twice through both equity reduction and margin changes.

Source: [NSE Clearing — equity derivatives margins](https://www.nseclearing.in/risk-management/equity-derivatives/margins).

## 8. Concentration and diversification

Provide separate views of:

- Gross and net directional exposure.
- Vega by underlying and expiry.
- Gamma near expiry.
- Contribution to stressed losses.
- Market and sector factor exposure.

Market value alone is insufficient: a short option can have a small premium value and substantial downside exposure. A nearly delta-neutral short straddle can still carry substantial gamma and vega risk.

Show the exposure basis and denominator for every concentration percentage.

Separate unique underlying counts from account-underlying group counts.

## 9. Liquidity risk

Use available quote and market-depth data to estimate:

- Bid–ask cost of closing the current position.
- Quote age and spread width.
- Depth relative to position size.
- Additional cost under wider-spread or reduced-depth assumptions.

Separate observable spread costs from modelled slippage. Do not promise execution at an analytical midpoint.

## 10. Risk history and drawdown

Store consistent portfolio and account snapshots.

Track:

- Exposure and Greek changes.
- Stressed loss over time.
- Margin utilisation and funding pressure.
- Historical model estimates versus subsequent outcomes.
- Cash-flow-adjusted portfolio returns and drawdown.

Deposits and withdrawals must not appear as investment gains or losses. Reconstruct comparable portfolio values and cash-flow-adjusted returns before presenting performance-based drawdown.

## Proposed page layout

1. **Summary cards:** key sensitivities, selected stressed loss, tightest account, and nearest expiry.
2. **Stress heatmap:** underlying move × IV move, with a horizon selector.
3. **Risk contributors:** account, underlying, expiry, and instrument breakdowns.
4. **Account funding:** reported margins, estimated stress requirements, and shortfalls.
5. **Expiry and settlement:** hedge mismatches, obligations, and readiness.
6. **Historical risk:** VaR, Expected Shortfall, diversification, and trends.

Every result should include:

- Account and instrument scope.
- Data and calculation timestamps.
- Broker-reported, calculated, or unavailable status.
- Relevant assumptions and units.
- A clear distinction between current-mark scenario loss and entry-based P&L.

## Delivery order

### First release

- Reliable normalized positions and market marks.
- Shared pricing engine.
- Greeks and normalized rupee sensitivities.
- Full-repricing stress scenarios.
- Account funding and margin provenance.
- Expiry payoff, hedge mismatches, and settlement readiness.
- Basic concentration views.

### Second release

- Historical VaR and Expected Shortfall.
- Correlation and factor views.
- Liquidity estimates.
- Risk history and drawdown.

### Later releases

- EWMA/GARCH forecasts.
- Correlated Monte Carlo.
- More detailed volatility-surface modelling.

Add complex models only when validation demonstrates useful improvements. Make the individual risk measures explainable before introducing an overall risk score.

## Validation and data requirements

- Use stable instrument identifiers and correct contract multipliers.
- Align prices, positions, and timestamps across accounts.
- Preserve original broker fields alongside normalized values.
- Test long and short options, futures, spreads, mixed expiries, and physical settlement.
- Check analytical Greeks against finite-difference estimates.
- Check expiry payoffs against independently calculated examples.
- Backtest VaR exceedances and investigate clustering and model drift.
- Assess tail-estimate stability and sensitivity to historical windows.
- Report incomplete portfolio coverage explicitly.
- Validate account-level funding calculations independently from market-risk calculations.

## Review against GoldenBook (15 October 2026, open for the owner's answers)

The assistant's proposal, debated with the owner and **not yet decided**. Each section was tested
against three questions: would a retail F&O option seller act on it; can it be computed honestly
from the data GoldenBook has (no bid/ask or depth, no stored price or IV history, no broker Greeks,
the option chain only through an Alice Blue connection, Paytm and Dhan marks sometimes missing);
and does the Payoff page already do it.

### Keep

1. **Stress scenarios: mostly built.** `HeuristicMarginEngine` already reprices each leg with
   Black-Scholes at a volatility solved from that leg's own mark, which captures the skew at
   current marks (§1's concern), and `ScenarioLadder` already evaluates ±5% and ±10%. Add IV
   shifts and a horizon. **Objection:** one portfolio heatmap moves every underlying by the same
   percentage, an unstated assumption of perfect correlation. Show the grid per account and
   underlying, plus one named "everything falls together" scenario labelled as a worst case.
2. **Funding under stress, per account: the strongest item.** Payoff cannot answer it, and it is
   what gets a user squared off. **Caveat:** the engine's SPAN runs about 24% below Zerodha's, so
   a stressed shortfall built on it errs reassuring. Show it as a range or "at least", or wait for
   NSE's daily SPAN risk parameter file.
3. **Expiry and physical settlement:** India-specific and undersold here. In-the-money stock
   options become delivery; brokers raise margins in the days before expiry and square off;
   shares count only in the same account. All from data already held (contract master,
   per-account holdings). "Hedge expires first" is one line in that list.
4. **Two Greeks only:** ₹ per 1% move and ₹ per day. Gamma as a number means little to most
   users, and the grid shows its effect. Delta-based exposure also replaces `ExposureCalculator`'s
   `qty × ltp`, which understates short options.

### Cut or defer until data exists

- **Historical VaR / Expected Shortfall:** needs index return *and* IV histories, neither stored,
  and IV history is not free. For short-option books a 95% VaR looks small while the damage sits
  in the tail, and it reads as a maximum loss. The stress grid answers "how much could I lose"
  more honestly.
- **EWMA, GARCH, factor regression, Monte Carlo:** fund tooling; books are 3–8 underlyings,
  mostly indices, and nothing exists to validate the models against.
- **Liquidity risk, and §1's "prefer midpoints":** no source supplies bid/ask or depth; marks
  are last prices.
- **Risk history and drawdown:** cash-flow adjustment needs a deposits/withdrawals ledger no broker
  API used here provides, and the snapshot pipeline is being retired (N13).
- **Factor/sector concentration:** keep only "largest contributors to the stressed loss", which
  falls out of the grid.

### Overlap with Payoff

§4's expiry payoff, maximum profit/loss and breakevens are the Payoff page's job already, per
(account, underlying), with its mixed-expiry caveat. The now / next day / chosen date horizon
belongs on Payoff's chart (its disabled T+0 toggle). Proposed split: **Risk is the across-everything
view** (one row per account and underlying with ₹/1%, ₹/day, loss at −5%, +5% and IV +5; the
per-account funding panel; the expiry and settlement list; each row links to Payoff), and Payoff
is the per-strategy depth.

### Missing from the plan

- **SEBI wording:** describe the user's own book, never what to do about it. "Consider closing X"
  is research-analyst territory.
- **Coverage on the page:** every figure says which legs it covers; a leg with no price or no IV
  solve is "not included", never zero risk.

### Open questions for the owner

1. Who is the page for: the owner and option-selling friends (then the four kept items are the
   page), or users holding mostly stocks?
2. Stress per underlying instead of one portfolio heatmap?
3. Is a SPAN estimate about 24% low good enough to print "short by ₹X", or does funding pressure
   wait for NSE's SPAN file?
