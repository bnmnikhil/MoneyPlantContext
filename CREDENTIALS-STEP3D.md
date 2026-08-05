# Step 3d — Per-user broker credentials

**Decided 5 Aug 2026.** Design spec. Sits beside `CLAUDE.md`, `UX-STEP2.md` and
`DEPLOY-STEP3.md`, above both repos, because it spans them.

**Sequencing: after 3c.** The deploy goes live on the env-var model first and is verified end
to end; this lands against a working system. Building a new persistence layer and a new
deployment at the same time means never knowing which one broke.

---

## The decision

> **All three brokers move to per-user credentials. Each user supplies their own key and
> secret, stored encrypted in Postgres. There is no app-level fallback.**

This reverses the position taken earlier the same day, when the vendor model was chosen and
per-user credentials were explicitly listed as out of scope. The reversal is deliberate.

**Why.** The vendor model leaves an unresolved question: whether Zerodha's and Paytm's terms
permit one app registration serving several users. Per-user credentials remove the question
rather than answer it — each user's API access is their own subscription, so there is no
redistribution to reason about. It is the compliant answer rather than the convenient one.

**The price, stated plainly.** Every user must create a developer app at each broker they
want to use, and Kite charges a monthly fee per app. Onboarding stops being "sign in with
Google and press Connect" and becomes "register a developer app, pay for it, paste two
values". That cost is real, and it is why this was not the first choice. It is accepted in
exchange for standing on solid ground with the brokers.

### Three things that fall out of it, worth having anyway

- **The broker startup guards disappear.** The app currently refuses to boot unless all six
  broker variables are set — the exact problem that forced a decision during deploy planning,
  when a VM with no Alice Blue registration could not start.
- **Each user registers their own redirect URL**, so the one-URL-per-registration constraint
  stops being a shared bottleneck.
- **`/api/session/status`'s `brokers` array becomes user-scoped** — "brokers *this user* has
  credentials for". That is the user-configured-brokers backlog item arriving early, and the
  two-array shape chosen for that endpoint survives unchanged.

---

## Scope

| | |
|---|---|
| Brokers | All three, per-user. No app-level fallback. |
| Database | Postgres in Docker now; only the JDBC URL changes to go managed later |
| Access | Spring `JdbcClient` + Flyway |
| Users | **No users table.** `MP_ALLOWED_EMAILS` still governs sign-in; rows key off the Google `sub` already in use |
| Secrets | AES-256-GCM, key in the environment, never in the database |

Nothing is Supabase-specific — plain JDBC, plain SQL — so moving to a managed provider is a
URL change.

This departs from CLAUDE.md's "Postgres + jOOQ" note for Step 7: jOOQ's codegen is not worth
a build step for one table. It remains available when Step 7 brings several.

---

## The architectural spine

CLAUDE.md's first rule is *"Gateways are stateless. `BrokerSession` is a parameter, never a
field."* Extend it:

> **Credentials are a parameter, never a field.**

Session services and gateways receive them per call; nothing holds them. That falls out of a
split which keeps the secret in one place:

| | Sensitivity | Where it lives |
|---|---|---|
| `apiKey` / `appCode` | identifier — already travels in login URLs | resolved at connect time, then rides in `BrokerSession.tokens` |
| `apiSecret` | high — signs the session exchange | read from the encrypted store only at session creation; never in a session, never in an API response, never logged |

`KiteBrokerGateway` builds `new KiteConnect(apiKey)` on **every call**, so the key has to be
reachable per request. Putting it in the session — already per-connection, therefore
per-user — avoids a database read per gateway call while keeping the secret out of it
entirely. The Alice Blue and Paytm gateways need only their session token and are untouched.

---

## Schema

One table. `src/main/resources/db/migration/V1__broker_credential.sql`:

```sql
create table broker_credential (
  user_id       text not null,          -- Google sub, as everywhere else
  broker_id     text not null,
  api_key       text not null,          -- apiKey or appCode; an identifier, not a secret
  secret_cipher bytea not null,
  secret_iv     bytea not null,         -- random per row
  key_version   int  not null default 1,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  primary key (user_id, broker_id)
);
```

**Keyed by `(user_id, broker_id)`, not by connectionId.** One Kite Connect app can authorise
two different Zerodha logins, so credentials belong to the broker relationship while account
labels stay a connection concern.

`key_version` exists so a key rotation is a backfill rather than a migration.

---

## Work

### New `credential/` package

Laid out like `auth/`.

| Class | Role |
|---|---|
| `BrokerCredentials` | record `(brokerId, apiKey, apiSecret)` — the parameter passed around |
| `CredentialCipher` | AES-256-GCM. Key from `MP_CREDENTIAL_KEY` (base64, 32 bytes), asserted at startup via the existing `common/RequiredConfig.requireResolved` |
| `BrokerCredentialRepository` | `JdbcClient`, four statements |
| `BrokerCredentialService` | `find`, `require`, `save`, `delete`, `brokerIdsFor(userId)` |
| `BrokerCredentialController` | `GET /api/broker-credentials`, `PUT /{brokerId}`, `DELETE /{brokerId}` |

**The GET never returns a secret** — only `{brokerId, apiKey, configured}`.

### Changed

- `BrokerAuthProvider.loginUrl(BrokerCredentials, String state)` — the interface change that
  drives everything else.
- The three session services: `createSession(BrokerCredentials, …)`; delete each
  `verifyCredentialsResolved()`; delete `KiteProperties`, `AliceBlueProperties`,
  `PaytmProperties`.
- The three callback controllers: after `pending.consume(state)` yields the userId, resolve
  that user's credentials before the exchange. `KiteSessionController` is the pattern.
- `KiteBrokerGateway` — api key from the session, not from properties.
- `SessionController.status()` — `brokers` becomes `credentials.brokerIdsFor(userId)`.
- `application.properties` — drop the six broker variables, add the datasource and
  `MP_CREDENTIAL_KEY`. Same removal in `tradestack/deploy/moneyplant.env.example`.
- `docker-compose.yml` — `postgres:16`, named volume, published on 5432.

### Frontend

A Settings page: each broker with its credential state, a form taking key and secret, and a
Remove action.

**The secret is write-only.** It is never sent back, so the field renders empty with "stored"
beside it — not a masked value, which would imply it could be revealed.

`ConnectBrokerCard` should send a user with no credentials to Settings rather than offering a
Connect button that cannot work.

---

## Verification

- **The crypto unit tests carry the weight**: round-trip, tampered ciphertext rejected,
  tampered IV rejected, wrong key rejected. A GCM authentication failure must surface as an
  error, never as garbage plaintext.
- Repository tests against Testcontainers, behind a tag excluded from the default build —
  the VM builds on 1 OCPU and `deploy.sh` runs the suite there.
- `SessionControllerTest` extends: a user with no credentials sees an empty `brokers` array;
  users never see each other's rows.
- End to end on the deployed host: store your own Kite key and secret in Settings → Connect →
  callback attributes correctly → positions load. Then confirm with `psql` that
  `secret_cipher` is unreadable bytes, and that `GET /api/broker-credentials` carries no
  secret.
- Restart the backend and reconnect, proving credentials survive while broker sessions
  correctly do not.

---

## Explicitly not in this step

A users table, self-service sign-up, account deletion, key-rotation tooling, saved strategies.
`MP_ALLOWED_EMAILS` keeps governing who may sign in.
