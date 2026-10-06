---
name: browser-urls-never-share-a-setting-with-server-urls
description: Any URL the app hands to a browser needs its own setting, separate from the base URL the server calls; staging sent a browser to 127.0.0.1 once
metadata:
  type: feedback
---

A broker login URL is reached from **two different places**: the server (generate-consent, token exchange, the API) and the
**user's browser** (the login page). On staging the server reaches the simulator on loopback while the browser must be sent
to the public host through Caddy.

**What went wrong (6 Oct 2026).** Dhan's login link was built from `GB_DHAN_AUTH_BASE`, the same base the server calls, so a
tester's browser was sent to `http://127.0.0.1:8190/...` and could not load it. It passed every local check because on a
laptop the browser and the server share a loopback. Upstox already had a separate `GB_UPSTOX_LOGIN_URL`; Dhan did not.

**Rule.** Every broker takes a **browser-facing login URL setting** distinct from its server base, and the endpoint guard
checks both. A test must fail if a loopback host reaches a browser (`DhanSessionAndGatewayTest`). When adding a broker
(Groww next), give it a `login-url` property from the start and check the URL the browser actually receives on staging
before declaring it working: load the page through the public staging URL, not just from the server.
