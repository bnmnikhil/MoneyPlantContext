# GoldenBook documentation

GoldenBook (`goldenbook.in`) is a **read-only viewer for NSE F&O traders who use more than one
broker**. It gathers positions, holdings and margins from each broker the user connects, puts them on
one screen, and draws payoff charts and a risk view from them. **It never places an order.**

These pages are the readable layer over the project's working documents, which live in git beside the
code and are kept current by the same pull requests that change the code. Nothing here is a second source
of truth: where a page summarises something, it links to the document that owns it.

## Start here

| If you want to know... | Read |
|---|---|
| What the product does, for whom, and what it deliberately does not do | [Product overview](product/overview.md) |
| What each number means, and the rules the app follows | [Business rules](product/business-rules.md) |
| Which brokers are supported, how each one logs in, and what each one gets wrong | [Brokers](product/brokers.md) |
| How the system is put together | [Architecture](architecture/overview.md) |
| How credentials, sessions and users are protected | [Security and data](architecture/security-and-data.md) |
| How a user connects a broker, step by step, per broker | [Connect flows](flows/connect.md) |
| What happens when a page loads, and how payoff and risk are computed | [Reading and analysis](flows/read-and-analysis.md) |
| How it is deployed, and the three environments | [Environments and deploy](operations/environments-and-deploy.md) |
| What is being worked on, and where the plan lives | [Planning](planning/index.md) |
| How these docs are kept honest | [Maintaining the docs](contributing.md) |

## The two kinds of document

**Truth documents** are exact and change with the code. `CLAUDE.md` (what is true of the code now), the
architecture decision records (why a decision was made), the trackers (`PUBLIC-LAUNCH.md`,
`BROKER-EXPANSION-PLAN.md`, `STAGING.md`, `OBSERVABILITY.md`) and the per-broker dossiers.

**These pages** explain. They are written for a reader who is not an agent and who wants the shape of the
thing first. When a page and a truth document disagree, the truth document is right and the page is a bug:
fix the page in the same pull request.

## Three repositories, one workspace

| Repository | What it holds |
|---|---|
| [`MoneyPlant`](https://github.com/bnmnikhil/MoneyPlant) (`tradestack/`) | The backend: Java 21, Spring Boot 4, Postgres, the deploy scripts |
| [`MoneyPlantFrontend`](https://github.com/bnmnikhil/MoneyPlantFrontend) (`frontend/`) | The web app: React, Vite, TypeScript |
| [`MoneyPlantContext`](https://github.com/bnmnikhil/MoneyPlantContext) (this one) | The plans, research, decisions, memory and these docs |
| [`broker-sim`](https://github.com/bnmnikhil/broker-sim) | The simulated brokers used by staging and local development |
