---
name: google-signup-modes
description: Explicit Google admission modes, legacy identity compatibility, and why disabling applies only at next sign-in.
metadata:
  type: decision
---

**Decided and implemented locally 3 Oct 2026.** The owner selected open sign-up
for any Google account with no user cap and asked to implement it as the first
technical deliverable. Staging, five broker simulators and observability remain
separate tasks; L4's versioned terms-acceptance screen is not part of L3.

Admission uses `GB_SIGNUP_MODE=allowlist|open|closed` (`goldenbook.signup`), with
safe `allowlist` default. Only allowlist mode requires a nonempty email list;
empty configuration never means public access. Open admits any verified,
nonblank Google email without filtering domain or counting users. Closed admits
existing subjects only. Changing the configured mode requires restart.

V9 creates `app_user` keyed by Google's subject, not email. Addresses can change
or be reused; uniqueness on email would merge identities and cross account data.
Successful login updates email and last seen while preserving creation time,
disabled state and nullable terms fields. Acceptance is not inferred from login.

Legacy subjects are seeded from all eight persisted user-owned tables so closed
mode does not lock out people whose only remaining record is history. Their
email remains null until the next verified Google sign-in because earlier tables
never stored it. A prior login with no durable broker/history record cannot be
reconstructed; that identity must register before closed mode is enabled.

The account-disabled check runs **only at sign-in**, in OIDC admission before an
authenticated session exists. A per-request check (`ActiveAppUserFilter`) was
built and then removed by the owner the same day: sign-up is open and nobody is
being turned away, so a database read on every API request bought nothing yet.
The cost accepted: a disabled user keeps an already-open session until the
midnight-IST expiry ends it, at most the rest of that day; a restart cuts it
immediately, because web sessions are in memory. Restore the filter if abuse ever
needs same-minute cut-off. Atomic login upserts check disabled state, protecting
against a disable racing admission. Database failures during admission refuse
sign-in generically; logs keep cause class/SQL state without identity/secret values.

The local loopback dev-auth bypass stays outside Google admission and requires no
app-user row. CSRF/logout, session fixation protection, midnight expiry, broker
ownership and `/api/me`'s existing shape stay intact.

**Enabled in production 3 Oct 2026, 14:47 IST**, by the owner, six days ahead of the
9 Oct plan; a new account registered at 14:51. The Google Console setting was not
changed by this work. Before claiming that any Google account can sign up, verify the External
audience and public redirect with fresh personal and Workspace accounts, and
complete L5's Production/branding work. Google's current docs describe a
basic-identity exception for `openid,email,profile` in Testing; do not infer a
mandatory 100-user cap from the generic Testing policy. Workspace administrators
can still block external apps. Source and enablement instructions are in
`tradestack/docs/google-signup.md`.
