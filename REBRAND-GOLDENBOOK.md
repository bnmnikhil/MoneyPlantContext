# Rebrand: MoneyPlant → GoldenBook, on `goldenbook.in`

**Created 2 Oct 2026.** The owner bought `goldenbook.in` and the product is renamed
**GoldenBook**. This file owns the rename and the domain move as **R-items**. It also
settles `PUBLIC-LAUNCH.md` **L2** (final domain), which is carried out here.
`PUBLIC-LAUNCH.md` still owns the launch schedule. Reasoning lives in
`memory/renamed-to-goldenbook.md`.

Status markers and the rule are `P0-LAUNCH.md`'s: `[ ]` `[~]` `[x]` `[-]`, and **`[x]`
only after the verification line has actually been run.** The work is on one branch name,
`launch/r-goldenbook-rename`, in all three repos.

## The one decision that shapes everything

**Everything is renamed, internal names included** (owner, 2 Oct 2026). That covers:

- what people see: UI, legal pages, host, consent screen, broker app names;
- the Java package (`com.goldenbook.tradestack`) and Maven groupId;
- `goldenbook.*` property keys and `GB_*` variables;
- the database, role, container and volume;
- systemd units, the `/opt`, `/etc`, `/var/www` and `/var/backups` paths, and the
  backup object prefix;
- the GitHub repos, and eventually the local folder.

The first draft of this plan kept the internals. The owner chose a full rename instead.
The two risks that draft named are handled rather than avoided:

- **Open branches:** the screener branch is already rebased onto the rename. The two
  launch frontend branches merge cleanly with it.
- **No tested rollback (D4):** `deploy/migrate-to-goldenbook.sh` copies the database
  volume and renames only the copy. The untouched original, plus a saved copy of the
  configuration and the live build, is a complete rollback.

`LegacyEnvironmentGuard` makes the backend refuse to start while any `MP_*` variable is
left. A half-migrated environment would otherwise drop `GB_COOKIE_SECURE` back to
`false` without a sound.

**Deliberately not renamed:**

- the Flyway migrations: changing a byte, even in a comment, fails checksum validation
  on the VM;
- the GitHub URLs, until R14 renames the repos;
- `C:\Projects\Moneyplant`, until R15;
- historical facts such as the old host and `~/.moneyplant/sessions.json`.

## Why this sits on the launch's critical path

Google brand verification (L5) takes days. It needs:

- a verified domain;
- a homepage on that domain that shows the **same name as the consent screen**;
- a live privacy policy linked from that homepage.

So L5 cannot start until the name is final, the DNS resolves, and a GoldenBook build is
live on `goldenbook.in`. The slow step is DNS: **R3 has to start today.**

---

## Summary

| ID | Item | When | Status |
|---|---|---|---|
| R1 | Spelling settled + trademark search | Fri 2 Oct | `[~]` |
| R2 | Host layout: everything on the apex `goldenbook.in` | Fri 2 Oct | `[~]` |
| R3 | DNS zone on Cloudflare, nameservers switched | **Fri 2 Oct** | `[ ]` |
| R4 | `support@goldenbook.in` mailbox that sends and receives | Fri 2 Oct | `[ ]` |
| R5 | Frontend rebrand: every user-visible string, logo, favicon, meta | Sat 3 Oct | `[~]` |
| R6 | Cutover: deploy + `migrate-to-goldenbook.sh` on the VM | Sat 3 – Sun 4 Oct | `[ ]` |
| R7 | Google: Search Console, consent screen, redirect URI | Sat 3 – Sun 4 Oct | `[ ]` |
| R8 | Owner's broker apps re-pointed to the new callbacks | after R6 | `[ ]` |
| R9 | Words outside the code: L1 emails, legal details, comms | before each is sent | `[~]` |
| R10 | Docs and runbook use the new names | with R6 | `[~]` |
| R11 | Retire the old host | after launch | `[ ]` |
| R12 | Internal identifiers renamed in code | Fri 2 Oct | `[~]` |
| R13 | This laptop: `GB_*` variables, local database and role renamed | before the next local run | `[ ]` |
| R14 | GitHub repos renamed; remotes and clone URLs updated | after R6 | `[ ]` |
| R15 | Local folder `C:\Projects\Moneyplant` → `GoldenBook` | after launch | `[ ]` |

---

## Fri 2 Oct: start the clocks

### `[~]` R1 — Spelling and a trademark search

**Spelling: `GoldenBook`** (owner, 2 Oct 2026). The code and docs use it everywhere, and
the domain is lowercase. **The trademark search is still open.**

**Search:** check IP India's public trademark search (`tmrsearch.ipindia.gov.in`) for
"GOLDENBOOK" and "GOLDEN BOOK" in classes **9** (software), **36** (financial services)
and **42** (SaaS). Also search the Play Store and MCA company names for an Indian
finance product with the same name. This is about ten minutes, and it should come
**before** the name reaches Google's review and three brokers' compliance teams. Not
legal advice. If a live mark exists in class 36, ask a lawyer before going further.

**Verify:** the spelling is recorded in this item, and the search result is recorded here
with the date.

### `[~]` R2 — Host layout: the apex serves everything

**Recommended:** the app, the API and the landing page all stay on one host, now
`https://goldenbook.in`, as they are today on the old host. `www.goldenbook.in` redirects
to the apex. Same-origin is load-bearing: the session cookie is per host, and
`SameSite=Lax` plus the CSRF cookie assume the SPA and the API share an origin.

The broker callbacks become `https://goldenbook.in/{kite,aliceblue,paytm}/callback`, and
they are **permanent**: they get pasted into every user's broker app. That stays true
even if a marketing site later replaces the landing page. Caddy routes those three paths
to `:8080` whatever serves the rest, so an `app.` subdomain buys nothing that cannot be
added later.

**Verify:** the owner confirms. Then this, the Caddyfile, `MP_FRONTEND_URL`, the Google
redirect URI and L6's guide all name the same host. That is also L2's verification.

### `[ ]` R3 — DNS on Cloudflare

Today's setup is Cloudflare DNS with a grey cloud (DNS only, no proxy) pointing at the OCI
reserved IP. Repeat it for the new zone:

1. Add `goldenbook.in` to Cloudflare (Free plan). Before switching nameservers, check that
   Cloudflare imported nothing unexpected from the registrar's default records.
2. At the registrar, set the nameservers to the two Cloudflare gives you. **This is the
   slow step:** usually under an hour for `.in`, but it can take up to 24–48 h.
3. Add `A goldenbook.in → <OCI reserved IP>`, grey cloud. Add `CNAME www → goldenbook.in`,
   grey cloud.
4. Optional, cheap: `CAA 0 issue "letsencrypt.org"`, since Caddy issues from Let's Encrypt.

**Verify:** `nslookup goldenbook.in 1.1.1.1` and `nslookup goldenbook.in 8.8.8.8` both
return the OCI IP, and Cloudflare shows the zone as *Active*.

### `[ ]` R4 — `support@goldenbook.in`

One address serves three uses: the E6 grievance contact, the Google consent screen's
support email, and the sender of the L1 broker emails. It must **send** from the domain,
not just receive. A compliance team reading a Gmail address that forwards from
`support@` sees a hobby project, and DMARC fails.

**Do:** a mailbox provider with a free custom-domain tier (Zoho Mail's free plan was the
usual choice; check that it is still offered), plus its MX, SPF and DKIM records and a
`DMARC p=none` record in Cloudflare. Cloudflare Email Routing alone only receives, so it
does not meet the "sends" requirement.

**If it is not live by Friday evening, do not hold L1 back:** send from the personal
address, name the product as "GoldenBook (goldenbook.in)", and put `support@` in the
signature once it works. L1 is the launch's critical path; a mailbox is not.

**Verify:** a message sent from `support@` to an outside Gmail address arrives with
`spf=pass`, `dkim=pass` and `dmarc=pass` in *Show original*, and a reply reaches the
mailbox.

---

## Sat 3 – Sun 4 Oct: rebrand and cut over (markets closed)

### `[~]` R5 — Frontend rebrand

**2 Oct 2026: done in code, not yet seen rendered.** `frontend 538d44f` on
`launch/r-goldenbook-rename`, stacked on `launch/e1-legal-pages`. Every string is
renamed, the open-book mark (gold) replaces the sprout in both logos and the favicon, and
`og:url` is set. 63 tests pass, the build is clean, and `git grep -i 'money ?plant'`
returns nothing. **Still open:** `og:image`, and the rendered check.

Commit on top of `launch/e1-legal-pages`. Since the legal pages name the operator and the
product, the two have to ship together. All of these are user-visible today (counted on
that branch, 2 Oct):

| Where | What |
|---|---|
| `index.html` | `<title>`, `og:site_name`, `og:title`; **add `og:url` and `og:image`**, which were waiting for L2 |
| `src/components/Logo.tsx` | wordmark (2 places), and the sprout glyph, which belongs to the old name; it needs a new mark (a book, in gold) |
| `public/favicon.svg` | the same mark |
| `pages/LandingPage.tsx` | 5 strings |
| `pages/LoginPage.tsx` | "Sign in to …", disclosure line |
| `pages/PrivacyPage.tsx`, `pages/TermsPage.tsx` | 4 and 12 strings |
| `features/legal/LegalFooter.tsx`, `LegalLayout.tsx`, `details.ts` | footer ©, read-only line, aria-label, the `pricing` placeholder |
| `features/session/ConnectBrokerCard.tsx` | 1 string |
| `components/layout/Topbar.tsx` | aria-label |
| `package.json` | `"name"`: harmless; rename it for tidiness |

The in-page event (`goldenbook:broker-session-lost`) and the code comments are renamed
too; both halves of that event are in this one repo. Out of scope: a gold colour palette. That is a design decision for
after launch, not part of a rename.

An `og:image` is a 1200×630 PNG in `public/`; with nothing better, use the new mark plus
the wordmark on the page background.

**Verify:**

- `git grep -n -i -E 'money ?plant'` returns nothing;
- `npm test` passes and `npm run build` is clean;
- the landing, login, privacy and terms pages are **seen rendered** at desktop and phone
  width. L7 still owes that check, so do both at once.

### `[ ]` R6 — Cutover to the new host

The vehicle is a production deploy, because Google's reviewer needs a GoldenBook homepage
with its privacy link on `goldenbook.in`. **Recommended:** bring the PUBLIC-LAUNCH L10
dark deploy forward to this weekend. Merge `launch/l8-settings-redesign` and
`launch/e1-legal-pages` (with R5) into `main`, then deploy `main` in both repos, with
sign-up still allowlisted. That also gets V5–V8 confirmed four days earlier.
Wednesday's L10 then becomes a smaller second deploy.

**Before it:** D1's restore-verify has been run. There is no rollback path yet (D4), so
a working backup is the safety net.

**On the VM, the cutover is `deploy/migrate-to-goldenbook.sh`** (runbook: "Migrating to
GoldenBook names" in `deploy/README.md`). It does steps 2–3 below together with the
internal renames (R12), so there is one maintenance window, not two. It refuses to run
until `goldenbook.in` resolves to the VM. `CONFIRM=yes` vouches for the three manual
preconditions: step 1 below, a lifecycle rule for the new `goldenbook/` backup prefix
(**without it, new backups are never deleted**), and the branch being pushed.

**Order matters**, because Google sign-in breaks if the host it returns to is not the
host it started from:

1. **R7 first:** add `https://goldenbook.in/login/oauth2/code/google` in Google Cloud.
   Keep the old URI for now.
2. **Caddyfile:** a `goldenbook.in` block identical to today's site block;
   `www.goldenbook.in { redir https://goldenbook.in{uri} permanent }`; and the old host
   becomes `moneyplant.bonamnikhilbabu.in { redir https://goldenbook.in{uri} 308 }`.
   **308, not 301,** so that a broker callback arriving as a POST stays a POST, and
   `{uri}` carries the query string with the request token. While users still have the
   old callback registered (R8), this redirect is what keeps their connect flow working.
3. `/etc/goldenbook/goldenbook.env`: `GB_FRONTEND_URL=https://goldenbook.in`. Restart.
4. Everyone signed in on the old host is signed out once, because the cookie was per host.
   That is expected; tell the allowlisted users in advance.

**Verify:**

- `https://goldenbook.in` serves GoldenBook with a valid certificate;
- `curl -sI https://moneyplant.bonamnikhilbabu.in/kite/callback?x=1` gives
  `308` → `https://goldenbook.in/kite/callback?x=1`;
- `www` redirects to the apex;
- a full Google sign-in completes on the new host;
- `/api/me` signed out returns 401;
- the runbook's nine steps pass on the new host.

### `[ ]` R7 — Google Cloud: domain, consent screen, redirect URI

1. **Search Console:** add `goldenbook.in` as a *Domain* property and verify it with the
   TXT record, which goes in Cloudflare.
2. **OAuth consent screen:**
   - app name **GoldenBook** (R1's spelling) and logo (R5's mark, 120×120);
   - home page `https://goldenbook.in`;
   - privacy `https://goldenbook.in/privacy` and terms `https://goldenbook.in/terms`;
   - authorised domain `goldenbook.in`, and the support email from R4.
3. **Credentials:** add the new redirect URI, as in R6 step 1. Remove the old one at R11,
   not before.
4. **Then submit L5** (Production + brand verification) under the new name only. **Do not
   submit under MoneyPlant and rename later**, because a rename restarts the review.

**Verify:** Search Console shows the domain as verified. A Google account not on any
test-user list sees "GoldenBook" on the consent screen once L5 is approved.

### `[ ]` R8 — The owner's broker apps

Each broker app the owner registered points at the old callback. The 308 keeps it
working, but L6's guide will print the new URL, and the owner's own setup should match
it before anyone else follows the guide.

**Do:**

- **Kite:** in the developer console, change the redirect URL to
  `https://goldenbook.in/kite/callback`, and rename the app to GoldenBook, since Kite
  shows the app name on its login screen.
- **Alice Blue and Paytm Money:** the same. Alice Blue may need its admin team to approve
  a change; ask before assuming self-service.
- **Users already allowlisted** have their own apps. Send them the new URL, and say that
  the old one keeps working until R11.

**Verify:** one live connect per broker on production, where the broker returns straight
to `goldenbook.in` with no 308 in the network log.

### `[~]` R9 — Words outside the code

**2 Oct 2026:** the L1 email drafts are renamed; the `grep` below returns 0. The legal
details and L16 are still to do.

| Where | Count | Notes |
|---|---|---|
| `research/BROKER-CONSENT-EMAILS.md` | 13 | **Rename before L1 is sent.** Name the domain in the description. Compliance answers attach to the name they were asked about. |
| `frontend/src/features/legal/details.ts` | — | operator, contact = R4's address, effective date |
| L16 announcement | — | write it as GoldenBook from the start |
| `OBSERVABILITY.md` | 25 | monitor targets, Telegram bot name; update when the O-items are built, not now |

**Verify:** `grep -ci moneyplant research/BROKER-CONSENT-EMAILS.md` returns 0 before any
email leaves.

### `[~]` R10 — Docs use the new names

**2 Oct 2026:** every doc in the three repos is renamed on `launch/r-goldenbook-rename`.
`CLAUDE.md` says plainly that the VM and this laptop still run the old names until R6
and R13. What remains at R6:

- the `Live at` line in `CLAUDE.md`;
- `tradestack/deploy/README.md`: the host table, the verification curls, and the
  troubleshooting `-H "Host: …"`;
- `PUBLIC-LAUNCH.md` L2 → `[x]`.

**Verify:** `git grep bonamnikhilbabu` in both code repos matches only the Caddyfile's
redirect block.

---

## After launch

### `[ ]` R11 — Retire the old host

The redirect costs nothing to keep; Caddy renews the certificate itself. Keep it until
every known user's broker app has the new callback (R8), and while the owner keeps
`bonamnikhilbabu.in`. Then remove the Caddy block and the old Google redirect URI, and
check the server log for traffic to the old host first.

**Verify:** a week of access logs shows no request to the old host before it is removed.

### `[~]` R12 — Internal identifiers, renamed in code

**2 Oct 2026, on `launch/r-goldenbook-rename`:**

- `tradestack 7e0a269`: the package, groupId, property keys, `GB_*` variables, default
  database and role, deploy files and the Caddyfile (the old host 308-redirects), plus
  `LegacyEnvironmentGuard`. **475 tests pass** (the previous 471 plus its 4).
- `tradestack 1f0231c`: `migrate-to-goldenbook.sh` and the runbook section with rollback.
  `bash -n` passes. **It has never run against a VM**: there is no second machine to
  rehearse on, so its first run is the real one. That is why it copies rather than renames
  the volume.
- `feat/index-spread-screener` is rebased onto the rename (`3e533ca`, **481 tests pass**).

**Verify:** after R6, on the VM:

- `systemctl status goldenbook` is active;
- `docker exec goldenbook-postgres psql -U goldenbook -d goldenbook -c 'select count(*) from flyway_schema_history'` succeeds;
- `grep -rE '^(export +)?MP_' /etc/goldenbook` returns nothing.

### `[ ]` R13 — This laptop

The renamed backend refuses to start while the `MP_*` user variables exist, and expects a
`goldenbook` database.

**Do**, with the local backend stopped:

- copy each `MP_*` user variable to `GB_*`, then delete the `MP_*` one;
- `GB_DB_URL` names `/goldenbook`;
- on 5433, as `postgres`:
  `alter database moneyplant rename to goldenbook; alter role moneyplant rename to goldenbook;`.

The role keeps its password because local Postgres 16 stores SCRAM; check
`pg_authid.rolpassword` first. **Pre-rename branches stop running locally after this**,
which is the point.

**Verify:** a fresh shell starts the backend on `launch/r-goldenbook-rename` with dev
auth, and `/api/me` answers.

### `[ ]` R14 — GitHub repositories

**Do:**

- `MoneyPlant` → `GoldenBook`, `MoneyPlantFrontend` → `GoldenBookFrontend`,
  `MoneyPlantContext` → `GoldenBookContext`;
- `git remote set-url` in every local clone and on the VM;
- the two clone lines in `deploy/README.md`.

GitHub redirects the old URLs, so nothing breaks in between. Do it after R6, so the
migration fetches from URLs it already knows.

**Verify:** `git ls-remote` against each new URL, locally and on the VM.

### `[ ]` R15 — The local folder

`C:\Projects\Moneyplant` → `C:\Projects\GoldenBook`, after launch. Three things key off
that path:

- the `frontend-legal` worktree's absolute links: run `git worktree repair`;
- editor workspaces;
- Claude Code's per-project memory directory, which must be moved by hand.

**Verify:** `git worktree list` is clean in both code repos, and the project memory loads
in a new session.
