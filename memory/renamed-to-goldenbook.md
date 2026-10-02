---
name: renamed-to-goldenbook
description: Oct 2026 the product became GoldenBook on goldenbook.in, and everything was renamed, internals included; the VM moves by a copy-then-rename script with a full rollback.
metadata:
  type: decision
---

**Decided 2 Oct 2026 (owner).** The owner bought `goldenbook.in`, and the product is
renamed from MoneyPlant to **GoldenBook**, spelled that way. This settles
`PUBLIC-LAUNCH.md` L2: the final domain is `goldenbook.in`, replacing
`moneyplant.bonamnikhilbabu.in`. The work is tracked in `REBRAND-GOLDENBOOK.md`.

**Why now, a week before launch.** The domain is baked into every user's broker app
through the callback URLs, so moving it after open sign-up would break every user's
connect flow ([[public-launch-is-open-signup]]). Google's brand verification also
reviews the name on the homepage and the consent screen together. Renaming after
approval restarts the review.

**Everything is renamed, internals included.** The first proposal was to rename only what
users, Google and brokers see, and keep the package, `MP_*` keys, database, units and
paths. Its two reasons were conflicts with open branches, and a database migration on a
VM with no tested rollback. The owner chose a full rename instead. Both risks are handled
rather than avoided:

- the open screener branch was rebased onto the rename the same day;
- `deploy/migrate-to-goldenbook.sh` copies the Postgres volume and renames only the copy.
  The untouched original, plus the saved configuration, jar and web root, is the rollback.

**Three traps the rename exposed**, each now guarded:

- `MP_COOKIE_SECURE` defaults to `false` under its new name, so an env file left
  half-migrated would silently drop the Secure flag. `LegacyEnvironmentGuard` refuses to
  start while any `MP_*` variable exists.
- The OCI lifecycle rule deletes by the prefix `moneyplant/`, so backups under
  `goldenbook/` would be kept forever, breaking the privacy policy's 30 days. A second
  rule is a precondition of the migration.
- A Flyway migration (`V4`) names the old product in a comment. Editing it would fail
  checksum validation on the VM, so the migrations are the one place the old name stays.

**Host layout.** Everything stays on one origin, the apex `goldenbook.in`, because the
session cookie and CSRF assume the SPA and the API share it. `www` redirects to the apex.
The old host answers **308** (not 301), so a broker callback keeps its method and query
string while users' broker apps still point at it.

**How to apply.** New code, keys and docs say GoldenBook, `goldenbook` and `GB_`. Until
the migration runs (R6 for the VM, R13 for the laptop), production and the local machine
still run under the old names. A `moneyplant` path in a VM command is the *current* state
of the VM, not a missed rename.
