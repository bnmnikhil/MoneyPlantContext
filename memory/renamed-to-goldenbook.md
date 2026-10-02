---
name: renamed-to-goldenbook
description: Oct 2026 the product became GoldenBook on goldenbook.in; only what users, Google and brokers see is renamed, internal moneyplant identifiers stay.
metadata:
  type: decision
---

**Decided 2 Oct 2026 (owner).** The owner bought `goldenbook.in`, and the product is
renamed from MoneyPlant to **GoldenBook**. This settles `PUBLIC-LAUNCH.md` L2: the final
domain is `goldenbook.in`, replacing `moneyplant.bonamnikhilbabu.in`. The work is tracked
in `REBRAND-GOLDENBOOK.md`.

**Why now, a week before launch.** The domain is baked into every user's broker app
through the callback URLs, so moving it after open sign-up would break every user's
connect flow ([[public-launch-is-open-signup]]). Google's brand verification also
reviews the name on the homepage and the consent screen together. Renaming after
approval restarts the review.

**Only the outside is renamed.** What users, Google and the brokers see changes:

- UI strings, the logo, meta tags and the legal pages;
- the host;
- the consent screen and broker app names.

The internal names are kept, on purpose:

- the Java package `com.MoneyPlant.tradestack`;
- the `moneyplant.*` property keys and `MP_*` variables;
- the database, role, container and volume;
- the systemd unit and the `/opt` and `/etc` paths;
- the in-page event name.

Rejected: a full rename in launch week. It conflicts with every open branch, and turns
a config change into a database and volume migration on a VM with no tested rollback.
If the package is ever renamed, do it after launch, when no other branch is open.

**Host layout.** Everything stays on one origin, the apex `goldenbook.in`, because the
session cookie and CSRF assume the SPA and the API share it. `www` redirects to the apex.
The old host answers **308** (not 301), so a broker callback keeps its method and query
string while users' broker apps still point at it.

**How to apply.** New user-facing copy says GoldenBook. A grep for "MoneyPlant" that hits
code identifiers is expected, not a missed rename. Until R1 records the spelling and the
trademark search, treat "GoldenBook" (camel case) as provisional.
