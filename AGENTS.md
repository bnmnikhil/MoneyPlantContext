# MoneyPlant working guide

This file applies to the workspace repository and the nested `frontend` and
`tradestack` repositories.

## Mandatory task start

Before changing any file:

1. Read `CLAUDE.md` and `memory/MEMORY.md` for current project context.
2. Run `git branch --show-current` and `git status --short` in every repository
   the task may affect.
3. Create a task branch in each affected repository before the first edit. Never
   make task changes directly on `main` or `master`.
4. Use the same branch name in the workspace, `frontend`, and `tradestack` when a
   task crosses repository boundaries. Prefer names such as `fix/payoff-futures`
   or `feat/option-chain`.
5. Tell the user which branch or branches were created.

Read-only investigation does not require a branch. Create one as soon as the
task changes from diagnosis to implementation.

If uncommitted changes are already present on `main`, preserve them and create a
new branch immediately; the working-tree changes will follow to the new branch.
Do not reset, discard, overwrite, or silently mix existing user changes. Report
the situation to the user.

## Change discipline

- Keep changes limited to the requested task and preserve unrelated files.
- Add regression coverage for calculation, financial-data, and API-contract
  fixes when a stable assertion is possible.
- Run the relevant tests and build before reporting completion. State the exact
  checks and any remaining limitation.
- Update durable project documentation when behavior or an architectural
  decision changes.
- Do not commit, push, open or merge a pull request, deploy, or publish unless
  the user has requested that action.

## Completion report

At handoff, state the active branch in each affected repository, summarize the
files and behavior changed, list verification results, and say clearly whether
anything was committed, pushed, or deployed.
