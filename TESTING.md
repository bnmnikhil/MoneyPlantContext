# GoldenBook testing entry point

Use one command from the workspace root:

```powershell
.\scripts\verify.ps1 -Scope changed
```

The verifier prints why each check was selected, the directory and command it
will run, and a final `PASS`, `FAIL` or `SKIP` summary. It does not hide Maven or
npm output. A failure exits with code 1 and includes a focused reproduction
command.

## Prerequisites

- Windows PowerShell 5.1 or PowerShell 7.
- Java 21. The backend uses its checked-in Maven wrapper.
- Node.js and npm, with `frontend/node_modules` installed.
- Git for changed-path selection and whitespace checks.
- Docker only for `-Scope integration`; normal scopes do not require it.

Normal unit, broker and build scopes require no broker credentials, static IP,
browser, database or live broker connection. A first Maven or npm run may still
download build dependencies when the local cache is empty.

## Scopes

| Scope | Checks | Typical use |
|---|---|---|
| `changed` | Inspects all three repositories; runs frontend test/build and backend clean test only where relevant | Default before handoff |
| `fast` | Frontend tests and typecheck; backend tests without `clean` | Inner loop |
| `frontend` | Diff check, tests, typecheck and production build | Any UI or TypeScript change |
| `backend` | Diff check and authoritative `mvnw clean test` | Any Java or API-contract change |
| `broker` | Broker-specific tests plus shared catalogue, fan-out, session and error contracts | Adapter work; requires `-Broker <id>` |
| `integration` | Docker preflight and backend suite including `db`-tagged Testcontainers tests | Persistence and migration work |
| `ui` | Explicitly reports the missing browser smoke pack as skipped | Tracks the current UI-test gap |
| `all` | All network-free frontend/backend gates; explicitly skips Docker integration and unavailable browser tests | Release-candidate local gate |

Preview selection without executing commands:

```powershell
.\scripts\verify.ps1 -Scope changed -DryRun
.\scripts\verify.ps1 -Scope broker -Broker kite -DryRun
```

## Deterministic changed-path mapping

`changed` reads `git status --porcelain` independently in the workspace,
`frontend` and `tradestack` repositories:

- Relevant `frontend` changes select `npm test`, `npm run typecheck` and
  `npm run build`.
- Relevant `tradestack` changes select `.\mvnw.cmd clean test`.
- Workspace documentation or orchestration changes select `git diff --check`.
- Known local-only backend artifacts (`.mcp.json`, stale generated architecture
  output and JVM crash/replay logs) do not force a backend build.

The mapping is printed before execution. Financial calculations, API contracts,
authentication and migrations live in `tradestack`, so any change to them gets
the full clean backend gate rather than a guessed subset.

## Broker verification

```powershell
.\scripts\verify.ps1 -Scope broker -Broker aliceblue
```

The verifier discovers `*Test.java` below that broker's test package and adds
the shared broker catalogue, fan-out, session and error tests. It fails clearly
when an adapter has no test profile; it never treats missing tests as a pass.
The reusable simulator and full shared adapter contract suite are the next
milestone, so this scope will expand without changing its command line.

## Integration verification

```powershell
.\scripts\verify.ps1 -Scope integration
```

This runs Maven with `-DexcludedGroups=` so the `db`-tagged Testcontainers tests
are included. Docker must be running. Integration is deliberately not folded
into `all`, because this workstation normally runs PostgreSQL directly and does
not keep Docker Desktop running.

## Reading results

- The authoritative backend test count is Maven's own `Tests run:` line under
  `Results:` from a clean run. Do not sum `target/surefire-reports`; stale XML
  files have produced false counts before.
- `npm run build` already invokes `tsc -b`; the standalone typecheck remains in
  frontend-focused scopes so contract failures are named directly.
- `npm run lint` is not a gate: `eslint` is not installed in the frontend.
- `SKIP` is visible project debt, not a successful test. Record it in handoffs.

## Handoff format

Every implementation handoff should state:

1. Active branch in the workspace, `frontend` and `tradestack` repositories.
2. Behavior and files changed.
3. Exact verifier command and its pass/fail/skip summary.
4. Checks skipped and why.
5. Whether anything was committed, pushed or deployed.

## Troubleshooting

- **Script execution is disabled:** run
  `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -Scope changed`.
- **`npm.cmd` not found:** install Node.js, open a new terminal and run
  `npm install` in `frontend`.
- **Java version failure:** `java -version` must report Java 21.
- **Integration Docker failure:** start Docker, confirm `docker info`, then rerun
  the exact command printed in the failure summary.
- **Broker profile missing:** create the broker test package and at least one
  `*Test.java`; the verifier lists profiles it can currently discover.
