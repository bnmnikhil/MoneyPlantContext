# Security and data

How the system protects the things that can hurt a user: broker credentials, live broker sessions, and the
isolation between users. For what is *not yet* in place see the gaps review in
[`NEXT-STEPS.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/NEXT-STEPS.md).

## What is sensitive, and how each thing is held

| Thing | Where it lives | Protection |
|---|---|---|
| A user's **API secret** at a broker | `broker_credential` | **AES-256-GCM**, fresh random IV per row, key in `GB_CREDENTIAL_KEY` and never in the database. Read only at session creation; never in a session, a response or a log. |
| A user's **API key** and optional **client id** | `broker_credential` | Stored in the clear. They are identifiers that already travel in login URLs, and showing them back is how a user confirms what they pasted. |
| A live **broker access token** | `broker_session` | The token map is sealed with the same key. A broker token can place orders wherever the broker's API allows it (Paytm's can), so it is treated as a secret. |
| The **Google identity** | the application session | The Google `sub` (never the email) keys everything a user owns. |
| **Every payload** a broker sent | `raw_capture` | Per user; no retention policy yet |

**`GB_CREDENTIAL_KEY` is the one unrecoverable secret.** It stands between a database dump and every user's live
broker secrets and sessions. It is deliberately not in the database and must stay backed up off the VM.
Rotation is a backfill driven by `key_version`, never an edit in place. A tampered ciphertext or a wrong key
fails loudly (GCM is authenticated) instead of yielding plausible garbage that would be handed to a broker.

## Per-user isolation

- **Everything is keyed by the user.** A connection id is `{userId}:{brokerId}:{label}`, and `ConnectionService`
  has no unscoped "all sessions" method on purpose: the shortest path through the code is always one user's data.
- **The user is taken from the security context, never from the request**, so no request names another user.
- **Fan-out is caller-scoped** ([ADR 0015](https://github.com/bnmnikhil/MoneyPlant/blob/main/docs/adr/0015-fan-out-is-caller-scoped.md)),
  and the spot cache is per user: a shared one once let one user's broker supply another user's price.
- **Cross-user isolation has not yet been tested against production** (launch item L11).

## Sign-in and sessions

- **Google OIDC.** The application session ends at **midnight IST**, however active the user is.
- **Admission** is `allowlist`, `open` or `closed`, backed by an `app_user` table; a user can be disabled.
- **A broker's callback is public**, because the session cookie does not survive the cross-site redirect. It is
  attributed instead by a **single-use nonce** minted in the authenticated `login-url` call; see
  [Connect flows](../flows/connect.md). Two brokers cannot carry the nonce and fall back to "exactly one pending
  connect, or refuse".
- **A dead broker token never logs the user out of GoldenBook.** Brokers' `401`s are converted to warnings before
  they reach the browser, because the web app treats any `401` as "sign in again".

## Secrets in the repository and the logs

- **No secret is committed.** Configuration holds placeholders; real values live in `/etc/goldenbook/goldenbook.env`
  (root-owned, mode 600). `BrokerCredentials.toString()` is overridden so a stray log line cannot print a secret.
- **Logs are kept in journald for 28 days** and no longer, so the privacy policy's retention claim is true.
  Caddy's access log drops every query string and the `Referer`, because callbacks carry broker tokens and the
  connect nonce.
- **Staging holds no production data** and uses its own database, key and Google redirect.

## The environment guard

`GB_ENVIRONMENT` is `production` (default), `staging` or `local`. At boot the backend refuses to start if
production is pointed at a simulator, or staging at a real broker, in either direction. A forgotten variable
fails closed to the strict case.

## Known gaps

Open and tracked, not hidden: no security headers, no rate limiting or request-size cap, no way for a user to
revoke a broker or erase their data, no dependency audit, and **no backups**. They are the first items of the
suggested order in the gaps review.
