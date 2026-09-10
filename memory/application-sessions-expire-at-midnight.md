---
name: application-sessions-expire-at-midnight
description: "MoneyPlant's Google-authenticated web session lasts until midnight IST; API polling cannot extend it into the next day"
metadata:
  type: decision
  decided: 2026-09-10
---

The MoneyPlant application login has an **absolute expiry at the next midnight
in Asia/Kolkata**. A request at or after that boundary invalidates the servlet
session; API requests then receive 401, which the frontend already turns into a
redirect to `/login`. With the authenticated shell's session-status polling, a
foreground tab notices the boundary within about one minute. Manual Sign out
continues to invalidate the session immediately.

**Why not the servlet timeout alone.** `server.servlet.session.timeout` measures
inactivity, and every positions or session-status poll refreshes it. The SPA
therefore defeated Spring Boot's previous 30-minute default while open, while a
quiet tab could expire early. Neither behaviour expressed the chosen policy of
"stay signed in for this calendar day".

`EndOfDaySessionFilter` stores the next IST midnight on the first authenticated
request and enforces that absolute instant. The servlet inactivity timeout is
24 hours only as a container cleanup/fallback value, ensuring it does not end a
same-day login early. No background scheduler is required: a session with no
request after midnight grants no access, and the first later request destroys
it before authorization.

**Application and broker sessions remain separate.** This boundary signs the
user out of MoneyPlant. It does not delete encrypted broker sessions from
`ConnectionService`/`broker_session`; those already have their own daily token
lifecycle and can be available again after the same Google user signs in.

Local `MP_DEV_AUTH=true` remains intentionally exempt in effect: its fixed dev
identity authenticates every request again, so Sign out and end-of-day expiry
cannot persist on a development laptop.
