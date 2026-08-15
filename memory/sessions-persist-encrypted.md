---
name: sessions-persist-encrypted
description: "Broker sessions survive a restart in encrypted Postgres rows, seamed at ConnectionService — driven by Paytm having no refresh token"
metadata:
  type: decision
  decided: 2026-08-07
---

`PostgresSessionStore` replaced `FileSessionStore`; the plaintext
`~/.moneyplant/sessions.json` and its class were **deleted**, not deprecated.
(ADR 0025.)

**Why it exists at all — Paytm.** Kite and Alice Blue re-auth is one button, so
losing their sessions on restart is a minor annoyance. Paytm's login is a
password *and* an OTP **every time**, issues three access tokens, and returns
**no refresh token** — there is no renewal path at all. Without persistence,
every backend restart costs a manual OTP.

**Why the seam is `ConnectionService`, not `broker/paytm`.** Even though Paytm is
the entire motivation, that service is already the single `connectionId`-keyed
chokepoint — and naming a broker there would break the standing rule that *a new
broker needs zero changes outside its own package*.

**Two deliberate behaviours that look like bugs:**

- **Only sessions created today in IST are restored** — stricter than any
  broker's real expiry. Restoring a dead token yields a confusing 401; expiring
  early costs a login the user was about to make anyway. A restart across an IST
  date boundary costs a login, by design.
- **Unreadable rows fail closed to "no sessions"** — a re-login, never a failed
  startup.

**Consequence worth holding on to:** the token map is sealed with the same key as
credentials, so `MP_CREDENTIAL_KEY` now protects **live logins**, not merely the
ability to start one. A Paytm access token can place orders.
