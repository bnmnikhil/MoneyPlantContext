---
name: dev-auth-bypasses-google-locally
description: "MP_DEV_AUTH replaces Google sign-in with a fixed OIDC identity on localhost — a second way in, deliberately not a second code path"
metadata:
  type: decision
  decided: 2026-08-20
---

`auth/DevAuthConfig` — off unless `MP_DEV_AUTH=true`, and when on it replaces
`SecurityConfig` entirely (both are `@ConditionalOnProperty` on the same flag,
opposite values). Every request arrives authenticated as a fixed identity and
every path is permitted, so a laptop needs no `GOOGLE_CLIENT_ID`, no redirect URI
registered for localhost, no network, and no allowlist entry.

**Why.** None of that machinery is doing any work while someone is editing a
payoff chart, and all of it can fail independently of the thing being worked on.
A fresh clone should run.

**The principal is a real `DefaultOidcUser` inside a real
`OAuth2AuthenticationToken`** — the exact shape Google's flow produces. That is
the load-bearing choice: `SecurityContextCurrentUser`, `AuthController` and every
`@AuthenticationPrincipal` are untouched, so dev auth cannot drift from what
production sees. CSRF stays on with the same cookie repository for the same
reason. **A second way in, not a second code path through the app.**

**Two guards, not one.** The flag alone would leave a single mistyped environment
variable between a reachable host and "anyone on the internet is the owner" — and
this chain permits the endpoints that read and write encrypted broker credentials.
So it additionally **refuses to start unless `app.frontend-url` is loopback**.
That value was chosen as the second signal because it must already differ per
host and is load-bearing in three places, so it cannot be left at its localhost
default on the VM without sign-in and the broker callbacks breaking first.

**`MP_DEV_USER_ID` is the Google `sub`, and it matters.** Everything user-scoped
keys off it — `broker_credential` rows, the `{userId}:{brokerId}:{label}`
connection id, session ownership. Set to the sub already in the local database
(`select distinct user_id from broker_credential`) and the broker credentials and
sessions sitting there keep working; leave it at the `dev-local-user` default and
they are simply invisible, not lost. It is set in the owner's user environment,
so `setx`'s "new processes only" rule applies.

**`AllowedEmails` skips its empty-list startup failure under dev auth** — with no
sign-in to gate, demanding a list would mean a fresh clone still could not boot
without knowing an address to name. The check is unchanged when the flag is off.

**Rejected: a Spring profile.** Every other per-host switch in this stack is an
`MP_`-prefixed environment variable read through `application.properties`
(`MP_SESSION_STORE`, `MP_COOKIE_SECURE`, `MP_FRONTEND_URL`), and one mechanism is
worth more than a marginally more idiomatic second one.

Frontend impact is zero: `LoginPage`'s button still points at
`/oauth2/authorization/google`, which the dev filter answers with a redirect to
`${app.frontend-url}/app` rather than letting it 404.

See [[sessions-persist-encrypted]] and
[[credentials-per-user-per-registration]] for what that user id keys.
