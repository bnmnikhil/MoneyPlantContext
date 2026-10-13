---
name: web-sessions-persist-in-postgres
description: "Oct 2026: the Google sign-in session moved from the JVM to Postgres (Spring Session JDBC) so a deploy stops signing every user out; unreadable sessions fail closed to a sign-in"
metadata:
  type: decision
  decided: 2026-10-13
---

The GoldenBook sign-in session (the Google one, not broker sessions) is stored in
Postgres via Spring Session JDBC, table V11, cookie `SESSION`. Before this it lived
in Tomcat's memory, so **every deploy or restart signed every user out**. That was
found during the 13 Oct 2026 usability session: each staging redeploy dropped the
owner back to `/login` mid-test. In production it would mean every deploy logs out
every user, which grows worse as deploys and users grow.

**Why Spring Session JDBC and not something else.** Postgres is already on the VM
and the project avoids new services (always-free tier). Boot's
`spring-boot-session-jdbc` keeps every existing setting: cookie flags and the 24h
timeout still come from `server.servlet.session.*`. The midnight-IST deadline
([[application-sessions-expire-at-midnight]]) is a session attribute, so it
survives a restart with everything else. Flyway owns the schema
(`spring.session.jdbc.initialize-schema=never`), copied verbatim from Spring
Session's own `schema-postgresql.sql`.

**Unreadable sessions fail closed.** Attributes are Java-serialised. After a Spring
Security upgrade, yesterday's bytes may not deserialise, and Spring Session's
default converter would then throw on every request carrying that cookie. That is
a 500 until the row expires. `auth/WebSessionStoreConfig` replaces the converter
with one that drops the attribute, so the request is a plain 401 and the user signs
in again. Same rule as broker sessions ([[sessions-persist-encrypted]]): a
re-login, never an error.

**What it cost.** The old way to cut off a disabled user that same day was "restart
the app". That no longer works. It is now
`delete from spring_session where principal_name = '<google sub>'`, which is better
because it signs out only that user. Documented in `tradestack/docs/google-signup.md`.

**Tests.** The default suite excludes `JdbcSessionAutoConfiguration` and keeps
container sessions, so `mvnw test` still needs no database.

**Verified on staging, 13 Oct.** The owner signed in, staging was redeployed (the
app restarted at 17:50:44), and `/api/me` still answered 200 with the Overview
loaded. The simulated broker login survived as well.
