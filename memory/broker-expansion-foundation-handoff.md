# Broker expansion foundation is ready for the simulator

Type: state
Date: 21 September 2026
Branch: `feat/read-only-broker-foundation` in the workspace, `frontend`, and
`tradestack`

## Session close state

The research and executable rollout plan for the ten-broker launch are saved in
`research/BROKER-LAUNCH-SHORTLIST.md` and `BROKER-EXPANSION-PLAN.md`. The
no-mandatory-static-IP expansion order is Upstox, Kotak Neo, Dhan and FYERS,
followed conditionally by Groww, Motilal Oswal and 5paisa. The existing three are
Kite, Alice Blue and Paytm Money.

The first implementation slice is complete but uncommitted:

- `tradestack` owns a broker catalogue at `GET /api/brokers`, including display
  metadata, developer portal, credential fields, authentication mode,
  availability and implemented capabilities.
- `POSITIONS` and `HOLDINGS` are the required `BrokerGateway` contract.
  `MARGINS` and `INSTRUMENTS` are optional and fail closed. Unsupported data is
  represented by `BROKER_CAPABILITY_UNSUPPORTED` / `UNSUPPORTED_CAPABILITY`,
  never an invented zero or a transient-call message.
- Kite, Alice Blue and Paytm explicitly opt into their current full gateway
  surface. A new gateway defaults to positions and holdings only.
- The authenticated frontend loads the catalogue once and uses it for broker
  names, credential labels, developer-portal links and safe callback-code
  validation. Hardcoded three-broker label maps were removed.
- ADR 0028 records the boundary and explicitly says credential persistence is
  still limited to `apiKey` plus `apiSecret`.
- `TESTING.md` and `scripts/verify.ps1` now provide the single verification
  entry point. `changed` maps dirty paths across all three repositories;
  `broker` discovers adapter tests plus shared contracts; Docker integration and
  the missing browser pack are reported explicitly rather than hidden.

Verification at session close:

- `.\scripts\verify.ps1 -Scope changed` — seven selected steps passed:
  workspace/frontend/backend diff checks, 58 frontend tests, frontend
  typecheck/build and 440 clean backend tests.
- `.\scripts\verify.ps1 -Scope broker -Broker kite` — diff check plus 74
  broker-specific/shared tests passed.
- The frontend build still reports the existing 898.01 kB Vite chunk-size
  warning. Diff checks print CRLF conversion warnings but no errors.

Nothing was committed, pushed, deployed or published. Preserve the pre-existing
untracked `tradestack` files `.mcp.json`, `docs/architecture/`,
`hs_err_pid36660.log`, `hs_err_pid5460.log`, and `replay_pid36660.log`; they are
not part of this task.

## Exact restart point

Start the next session by reading `CLAUDE.md`, `memory/MEMORY.md`, this file and
`BROKER-EXPANSION-PLAN.md`, then confirm all three repositories are still on
`feat/read-only-broker-foundation` and inspect their dirty state before editing.

The next executable milestone is Phase 2 of the expansion plan: build the
reusable dummy-broker simulator, then add the shared adapter contract suite and
Upstox authentication, positions and holdings fixtures before writing the
production adapter. Live no-static-IP certification remains a separate gate
requiring controlled broker portal accounts and a test from an unregistered
dynamic IP.
