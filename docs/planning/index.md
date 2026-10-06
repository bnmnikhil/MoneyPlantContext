# Planning

## Where the plan lives

The plan is a set of trackers in the context repository. Each owns one area, uses the same status markers, and
may mark an item done **only after its verification line has actually been run**.

| Marker | Meaning |
|---|---|
| `[ ]` | Not started |
| `[~]` | In progress, or built but not verified |
| `[x]` | Done and verified |
| `[-]` | Deferred or not applicable |

| Tracker | Owns |
|---|---|
| [`PUBLIC-LAUNCH.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/PUBLIC-LAUNCH.md) | **What is being worked on now**: the open sign-up launch, its L-items, and the **session handoff** at the top |
| [`P0-LAUNCH.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/P0-LAUNCH.md) | Production readiness: correctness, security, deploy, legal (items A to F) |
| [`BROKER-EXPANSION-PLAN.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/BROKER-EXPANSION-PLAN.md) | Adding brokers: certification, foundations, simulators, one phase per broker |
| [`STAGING.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/STAGING.md) | Staging and the broker simulator |
| [`OBSERVABILITY.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/OBSERVABILITY.md) | Logs, metrics, dashboards and alerting |
| [`REBRAND-GOLDENBOOK.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/REBRAND-GOLDENBOOK.md) | The rename and domain move |
| [`NEXT-STEPS.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/NEXT-STEPS.md) | The residual backlog, the owner's ideas, and the **gaps review** |
| [`TESTING.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/TESTING.md) | The single verification entry point |
| `research/` | Dated findings: broker dossiers, regulatory and terms research |

**Start a session at the handoff block in `PUBLIC-LAUNCH.md`.** It says what is deployed, what is unverified,
what the owner is waiting on, and the next work in order. It is replaced, not appended to, at the end of each
session.

## Where things stand (6 October 2026)

- **Live:** open sign-up; five brokers, two of them (Upstox, Dhan) switched on before certification; rollout
  states; staging with a simulator.
- **Top open items:** live certification of Upstox and Dhan on a real account; backups; monitoring and alerts;
  security headers, rate limits and a revoke path; a support contact and data erasure; the risk page's stale
  positions.
- **Ideas queued by the owner:** an application dashboard, these docs, and a marketing and SEO pipeline.

The detail is in the handoff and in the gaps review; this page does not repeat it.

## How work is organised

1. An item is taken from a tracker, **a branch carries its id**, and the same branch name is used in both
   application repositories when a change spans them.
2. A change is **proven before it ships**: tests, then staging against the simulator, then (for a broker) a real
   account.
3. **Merged is not deployed.** Releases are a separate, deliberate step, with a plan for anything risky
   (`RELEASE-ADAPTERS-PLAN.md` is the model).
4. **Decisions are recorded where a future reader will look**: a memory note for the reasoning, an ADR for an
   architectural decision, the tracker for the status.

## Proposed: a board over the trackers

The trackers are precise but hard to scan. A board would give the same items a column view, a priority and a link
to the pull request that closes them. Recommended: **GitHub Projects**, one board across the four repositories,
with issues created from the tracker items. It is not set up yet; if it is, the trackers stay the authority for
status and an item's id is its issue's title, so the two cannot drift.

| Column | Meaning |
|---|---|
| Ideas | Owner ideas awaiting triage (`NEXT-STEPS.md`) |
| Planned | In a tracker, not started |
| In progress | A branch exists |
| In review | A pull request is open |
| Shipped, unverified | Deployed, the verification line not yet run |
| Done | Verified |
