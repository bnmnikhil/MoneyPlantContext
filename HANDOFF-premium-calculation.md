# Positions Premium Investigation

**Historical handoff.** See `P0-LAUNCH.md` for current release status (9 Sep 2026).
The premium fixes and tests are included in `feat/payoff-chart-range`; the user
has since connected brokers and accepted the live views. The pending-login notes
and local process details below describe the original investigation checkpoint.

Last checkpoint: 2026-09-06 21:56 IST.

The user subsequently reported the futures payoff graph. Local broker login is
now available and that follow-up is recorded in `HANDOFF-payoff-futures.md`.
The sections below describe the earlier premium investigation checkpoint.

## Current Task

The user asked to understand MoneyPlant and investigate an apparently incorrect
available-premium calculation on the positions page. They also asked for frequent,
clear progress commentary and for this handoff to be kept current so work can
resume after context exhaustion.

**Work remains: reconcile the user's actual positions after broker login.**
The frontend fix below is implemented and tested, but the user's specific live
discrepancy has not been reproduced. The user said they need to log in to provide
the data. Both local servers are ready; the last API check showed zero connected
accounts and zero positions. The user has been given http://localhost:5173/app.

## Definition Still To Confirm

An optional question was sent asking whether "available premium" means current
net option value (the existing "Premium left" column) or remaining time value
after subtracting intrinsic value. There has been no answer or example yet.

The current implementation preserves the existing definition:

`premiumLeft = sum(-(signed quantity * LTP))` over CE/PE options only.

Quantities already include lot size. Positive is net short option value; negative
is net long option value. This includes intrinsic and time value and is not a
guaranteed remaining profit or a time-decay measure. Do not claim that a
time-value-only feature has been implemented. If that is what the user wants,
agree the meaning using their position example before changing the metric.

## Repositories And Architecture

- Workspace/root context repo: `C:\Projects\Moneyplant`, main at `30edec3`.
- Frontend repo: `frontend`, main at `c8ab2ae`. React 18, TypeScript, Vite,
  Tailwind/shadcn, TanStack Query. Positions refresh from `/api/positions`.
- Backend repo: `tradestack`, main at `0b95e40`. Java 21, Spring Boot 4.1.0,
  PostgreSQL, adapters for Kite, Alice Blue and Paytm.
- Live positions: `PositionsController -> BrokerService -> broker gateways`.
  `BrokerService` adds contract-master facts. The frontend groups by account,
  underlying and option right. Identical instruments at different accounts stay
  separate. Margin is supplied independently by `/api/risk/summary`, which has
  known snapshot-freshness limitations; premium must use the live rows.
- Read `CLAUDE.md` and `memory/MEMORY.md` for architecture and durable decisions.
  No AGENTS.md was found in the workspace or checked parent paths.
- `rg` is unavailable; use PowerShell Get-ChildItem/Select-String or git tools.
  Use `Get-Content -Encoding UTF8` for existing Unicode documentation.

## Implemented Changes

All changes are local and uncommitted. Nothing was deployed, pushed or published.
No backend source was changed.

- `frontend/src/features/positions/grouping.ts`: only CE/PE positions contribute
  option premium and entry premium. FUT/EQ return null for their premium cells.
  Unknown types make subtotals incomplete. Missing quotes, even with stale
  nonzero LTPs, and invalid LTPs are excluded. No measurable options means null,
  a genuinely quoted zero stays zero, and closed options have zero remaining
  premium without needing a quote. Shared aggregation applies these rules to
  rights, underlyings and accounts. Entry minus left is unrealised P&L.
- `frontend/src/components/PremiumFigure.tsx`: nullable entry value; partial
  totals use `?` instead of `+?`, because missing longs can decrease the total.
  Incomplete totals hide entry comparisons and the percentage-of-margin hint.
  Tooltips distinguish current option value, time value, and realised P&L.
- `frontend/src/features/positions/PositionsTable.tsx`: desktop/mobile use the
  nullable helper; mobile right subtotals also show missing-data state.
  Missing LTPs display a dash instead of an apparent zero.
- `frontend/tests/positions-premium.test.mjs`: eight regression tests using the
  built-in Node test runner and TypeScript stripping, with no new dependencies.
  `frontend/package.json` adds `npm test`; frontend README documents it.
- Root documentation updated: `CLAUDE.md`, `memory/MEMORY.md`,
  `memory/premium-left-is-negated-market-value.md`, and
  `memory/an-unmeasured-zero-is-a-claim.md`.

## Verification Completed

- Regression suite first ran against the original code: 2 passed, 6 failed.
  A fixture with 800 rupees of option premium showed -11800 after equity/futures
  notionals were incorrectly included.
- `npm test` after the fix: all 8 tests passed on Node 24.5.0.
  Covers signs/lot units, non-options, missing/stale quotes, unresolved types,
  known zero/closed positions, invalid prices, account isolation, partial closes.
- `npm run build`: passed TypeScript and Vite production bundling. Existing
  large-chunk warning remains. The last subsequent source edit only clarified
  a comment and corrected tooltip grammar; no calculation changed afterward.
- `git diff --check`: passed in frontend and root context repo.
- Backend startup compiled current main successfully. No backend tests were
  rerun because backend source was unchanged.
- Browser verification was NOT completed: the browser skill was read, but the
  initial in-app browser bootstrap call was canceled by the user. No screenshots
  were taken and no authenticated browser session was inspected. Use that skill
  if browser work resumes; its complete runtime documentation was not obtained.
- HTTP checks succeeded through the frontend proxy: `/api/me` returned 200;
  `/api/session/status` listed all three configured brokers but no connections;
  `/api/positions` returned zero positions and zero warnings.

## Running Local Services

- Frontend: http://localhost:5173/app (also http://127.0.0.1:5173/app/positions).
  Vite PID at startup: 29660. Launched with node and `windowsHide: true`.
  Runtime logs, ignored by git: `frontend/vite-premium.stdout.log` and
  `frontend/vite-premium.stderr.log`. Launcher exec session ID: 23944; the tool
  continued reporting it running while the intended persistent server was live.
- Backend: http://127.0.0.1:8080, bound to loopback.
  Started using `mvn spring-boot:run "-Dspring-boot.run.arguments=--server.address=127.0.0.1"`.
  Exec session ID: 1265. Java PID at startup: 31672.
  Startup completed successfully; PostgreSQL localhost:5433 is reachable,
  Flyway schema version 8 is current, and no migration was necessary.
- Development app authentication is enabled by existing `MP_DEV_AUTH` settings.
  The user needs broker connection/login in the app, not Google app sign-in.
  Startup discarded three expired/unreadable stored broker sessions as designed.
- Environment credentials were checked only for presence and not printed.
  Do not copy secrets or broker tokens into this file or tool output.
- Recheck service availability after a resume; process and session IDs may expire.

## Startup Issues Already Resolved

- PowerShell `Start-Process` failed due to duplicate environment keys Path/PATH.
  The frontend was then successfully launched via Node child_process with
  detached mode, hidden window and redirected logs.
- `mvnw.cmd` failed inside its PowerShell bootstrap with a null-array error.
  Installed Maven at `C:\softwares\apache-maven-3.9.12\bin\mvn.cmd` works.
- Sandboxed Maven dependency resolution failed with `Permission denied: getsockopt`.
  The same startup command was rerun with required escalation, which succeeded.
  A `mvn spring-boot:run` prefix was requested. Do not work around sandbox denials.

## Next Checkpoint

1. Let the user connect their broker at http://localhost:5173/app. Maintain clear
   commentary and update this file after meaningful progress.
2. Once connected, read `/api/positions` through the local API and compare each
   relevant option's quantity and LTP with its premium. Compare right, underlying
   and account totals using the shared grouping helper. Check priceKnown and
   instrumentType before trusting a price or excluding a row.
3. Ask for the affected symbol and expected value if the discrepancy remains
   unclear. Confirm whether their intended metric is full premium or time value.
4. If new evidence requires changes, keep them scoped, add meaningful regression
   coverage, and rerun affected checks. Do not mark the live discrepancy resolved
   solely because the synthetic regression suite passed.
5. Update this handoff with the actual live result and remaining work, then give
   the user a concise result including limitations.

## Existing Unrelated Files

Preserve pre-existing untracked `.claude/` folders in root/frontend, and backend
`.mcp.json`, `docs/architecture/`, `hs_err_pid36660.log`, `hs_err_pid5460.log`,
and `replay_pid36660.log`. Do not commit or remove them as part of this task.

No sub-agents have been used; delegation is not authorized for this task.
