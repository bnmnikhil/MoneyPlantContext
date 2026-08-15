---
name: credentials-per-user-per-registration
description: "Every user registers their own developer app at each broker; credentials key on (user_id, broker_id, label) because one app can authorise several logins"
metadata:
  type: decision
  decided: 2026-08-07
---

`broker_credential` is keyed **`(user_id, broker_id, label)`** — a *registration*,
not a connection.

**Why not key by connectionId.** One Kite Connect app can authorise two different
Zerodha logins. Keying on the connection would force a duplicate credential row
per account and leave two copies of one secret to rotate.

**Why each user registers their own app.** There is no app-level registration for
any broker any more. That removes two problems at once: whether one registration
may lawfully serve several users, and the one-redirect-URL-per-registration
bottleneck that made `localhost` and the live domain mutually exclusive.

**The cost is onboarding effort, not money.** Kite Connect's **Personal tier is
₹0** and covers every endpoint this app calls. The ₹500/month Connect tier adds
only WebSocket and historical candles, neither of which is used — spot comes from
Paytm.

**The split by sensitivity is the important part.** `apiKey`/`appCode` is an
identifier that already travels in login URLs, so it is resolved at connect time
and rides in `BrokerSession.tokens`. `apiSecret` is read from the encrypted store
**only at session creation** — never in a session, never in a response, never
logged, and `BrokerCredentials.toString()` is overridden so a stray
`log.info("{}", creds)` cannot leak it.

**AES-256-GCM, not CBC**, because it is authenticated: a tampered ciphertext, a
tampered IV or a wrong key fail loudly, instead of yielding plausible garbage
that would be handed to a broker as a secret and returned as "invalid auth code".
A fresh random IV per seal is **not optional** — reuse under one key voids the
guarantee.

Related: [[sessions-persist-encrypted]], [[brokers-become-user-configured]]
