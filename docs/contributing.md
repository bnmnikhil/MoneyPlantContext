# Maintaining the docs

## Principles

1. **Git is the source of truth.** These pages live in `docs/` in the context repository and change in pull
   requests. There is no second copy in another tool to fall out of date.
2. **A page explains; a truth document states.** Do not copy a table that `CLAUDE.md` or an ADR owns. Summarise,
   then link.
3. **The pull request that changes behaviour updates the page.** A reviewer should be able to ask "which page does
   this change?" the way they ask "which test?".
4. **Say what is unknown.** An unverified figure, a missing safeguard or an open question belongs on the page, in
   plain words. The product's rule about unknown numbers applies to its documentation too.

## Which page to update

| You changed... | Update |
|---|---|
| What a number means, a calculation, a user-facing rule | [Business rules](product/business-rules.md) |
| A broker's behaviour or a new broker | [Brokers](product/brokers.md), [Connect flows](flows/connect.md) |
| Package layout, a module boundary | [Architecture overview](architecture/overview.md) |
| How credentials, sessions or isolation work | [Security and data](architecture/security-and-data.md) |
| The read path, payoff, spot, risk | [Reading and analysis](flows/read-and-analysis.md) |
| Environments, deploy steps, flags | [Environments and deploy](operations/environments-and-deploy.md) |
| What is planned or done | The tracker that owns it, then [Planning](planning/index.md) if the shape changed |

## Diagrams

Diagrams are **Mermaid**, written inline in a fenced block marked `mermaid`. They render on GitHub and in the
site, and a diagram is a text diff in review. Keep each to what one reader can take in at once; split a flow
rather than shrinking it.

## Previewing the site

```
python -m venv .venv-docs
.venv-docs\Scripts\pip install -r requirements-docs.txt
.venv-docs\Scripts\mkdocs serve
```

then open `http://127.0.0.1:8000`. `mkdocs build --strict` fails on a broken link or a page missing from the
navigation, and is the check to run before a pull request.

## Where it is hosted, and publishing

The site is served from the VM at **`https://staging.goldenbook.in/docs/`**, behind the same basic auth and
`noindex` as the rest of that host. It describes operations and known gaps, so it is never on the public host
(`goldenbook.in/docs/` shows the app's own page, not these).

To publish after a change, from the workspace root:

```
.\scripts\publish-docs.ps1
```

It runs the strict build (a broken link stops it before anything is uploaded), uploads the result, and swaps the
directory on the VM in place. The files live in `/var/www/goldenbook-docs`, a directory of their own that a staging
deploy cannot wipe. The Caddy block that serves it is in `tradestack/deploy/Caddyfile`.

**Publishing is manual for now**, so merging a docs change does not update the site until someone runs the
script. A scheduled or on-merge publish needs CI, which does not exist yet (see the gaps review).

## Not yet decided

A dedicated host such as `docs.goldenbook.in` (this needs a DNS record and moves nothing but the address), and
whether to add a board over the trackers (see [Planning](planning/index.md)).
