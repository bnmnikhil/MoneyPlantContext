# Rebrand: MoneyPlant → GoldenBook, on `goldenbook.in`

**Created 2 Oct 2026.** The owner bought `goldenbook.in` and the product is renamed
**GoldenBook**. This file owns the rename and the domain move as **R-items**. It also
settles `PUBLIC-LAUNCH.md` **L2** (final domain), which is carried out here.
`PUBLIC-LAUNCH.md` still owns the launch schedule. Reasoning lives in
`memory/renamed-to-goldenbook.md`.

Status markers and the rule are `P0-LAUNCH.md`'s: `[ ]` `[~]` `[x]` `[-]`, and **`[x]`
only after the verification line has actually been run.** Branch names carry the id
(`launch/r5-rebrand-frontend`).

## The one decision that shapes everything

**Rename what people see; keep the internal names.** Users, Google, the brokers and the
legal pages see the brand and the host. The Java package, `moneyplant.*` property keys,
`MP_*` variables, the database, role, container and volume, the systemd unit and the
`/opt` paths stay as they are. Users see none of them. Renaming them in launch week would
conflict with every open branch, and would turn a config change into a database and
volume migration on a VM that has no tested rollback (D4). See R12.

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
| R1 | Spelling settled + trademark search | Fri 2 Oct | `[ ]` |
| R2 | Host layout: everything on the apex `goldenbook.in` | Fri 2 Oct | `[~]` |
| R3 | DNS zone on Cloudflare, nameservers switched | **Fri 2 Oct** | `[ ]` |
| R4 | `support@goldenbook.in` mailbox that sends and receives | Fri 2 Oct | `[ ]` |
| R5 | Frontend rebrand: every user-visible string, logo, favicon, meta | Sat 3 Oct | `[ ]` |
| R6 | Cutover: Caddy, `MP_FRONTEND_URL`, old host 308-redirects | Sat 3 – Sun 4 Oct | `[ ]` |
| R7 | Google: Search Console, consent screen, redirect URI | Sat 3 – Sun 4 Oct | `[ ]` |
| R8 | Owner's broker apps re-pointed to the new callbacks | after R6 | `[ ]` |
| R9 | Words outside the code: L1 emails, legal details, comms | before each is sent | `[ ]` |
| R10 | Docs and runbook name the new host | with R6 | `[ ]` |
| R11 | Retire the old host | after launch | `[ ]` |
| R12 | Internal identifiers kept, on purpose | — | `[-]` |

---

## Fri 2 Oct: start the clocks

### `[ ]` R1 — Spelling and a trademark search

**Decide:** `GoldenBook` (camel case, as `MoneyPlant` was) or `Goldenbook`. Every string
in R5, the consent screen and the broker emails uses the same one. The domain is lowercase
either way.

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

### `[ ]` R5 — Frontend rebrand

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

**Not renamed**, deliberately (R12): `BROKER_SESSION_LOST_EVENT`'s value
`"moneyplant:broker-session-lost"` in `lib/api.ts`, which no user sees and whose rename
would need both halves to deploy together, and the code comments in `aggregate.ts` and
`types/api.ts`. Also out of scope: a gold colour palette. That is a design decision for
after launch, not part of a rename.

An `og:image` is a 1200×630 PNG in `public/`; with nothing better, use the new mark plus
the wordmark on the page background.

**Verify:**

- `git grep -n -i -E 'money ?plant' -- src index.html public package.json` returns only
  the event-name line and the two comments;
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
3. `/etc/moneyplant/moneyplant.env`: `MP_FRONTEND_URL=https://goldenbook.in`. Restart.
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

### `[ ]` R9 — Words outside the code

| Where | Count | Notes |
|---|---|---|
| `research/BROKER-CONSENT-EMAILS.md` | 13 | **Rename before L1 is sent.** Name the domain in the description. Compliance answers attach to the name they were asked about. |
| `frontend/src/features/legal/details.ts` | — | operator, contact = R4's address, effective date |
| L16 announcement | — | write it as GoldenBook from the start |
| `OBSERVABILITY.md` | 25 | monitor targets, Telegram bot name; update when the O-items are built, not now |

**Verify:** `grep -ci moneyplant research/BROKER-CONSENT-EMAILS.md` returns 0 before any
email leaves.

### `[ ]` R10 — Docs name the new host

Done at R6, not before, because `CLAUDE.md` describes code truth:

- the `Live at` line in `CLAUDE.md`;
- `tradestack/deploy/README.md`: the host table, the verification curls, and the
  troubleshooting `-H "Host: …"`;
- `deploy/moneyplant.env.example`'s `MP_FRONTEND_URL` (the file name stays, per R12);
- `PUBLIC-LAUNCH.md` L2 → `[x]`.

`DevAuthSecurityTest:73` uses the old host only as an example of a non-loopback URL, so
it is optional; changing it costs one line.

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

### `[-]` R12 — Internal identifiers, kept on purpose

| Identifier | Where | Why it stays |
|---|---|---|
| `com.MoneyPlant.tradestack` | every Java file | No user sees it, and renaming it conflicts with every open branch. If it is ever done, do it in a post-launch PR **when no other branch is open**, and fix the non-standard capital at the same time (`com.goldenbook`). |
| `moneyplant.*` property keys, `MP_*` variables | `application.properties`, VM env | Renaming means changing the VM env and the code in the same deploy, for no gain. |
| database / role `moneyplant`, `moneyplant-postgres`, `moneyplant-pgdata` | VM, `docker-compose.yml`, `backup.sh` | A volume rename is a dump-and-restore on the one machine with no rollback. Never worth it. |
| `moneyplant.service`, `/opt/moneyplant`, `/etc/moneyplant`, `/var/www/moneyplant` | VM, `deploy/` | The same: host plumbing that nobody else sees. |
| `"moneyplant:broker-session-lost"` | `lib/api.ts` | An in-page event name. |
| GitHub repos, `tradestack` | GitHub | GitHub redirects renamed repos, so this is cheap whenever it is wanted; it is not needed for launch. |

Revisit after launch only if one of these starts confusing a contributor. That is the
only cost they carry.
