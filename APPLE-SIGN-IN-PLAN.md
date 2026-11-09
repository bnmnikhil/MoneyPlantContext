# Sign in with Apple: implementation plan

Created 30 October 2026. Status: proposed; documentation only. No application changes,
Apple registration, migration, commit, push or deployment is authorized by this plan.

## Outcome

Offer Continue with Apple alongside Google. Both providers establish the same GoldenBook
application session and use the same signup, disabled-account and midnight-IST policies.
Google and Apple identities create separate GoldenBook accounts, even when their verified
emails match. Each account owns its own broker registrations and data. Broker authentication
remains separate. Linking and merging are deferred by owner decision on 30 October 2026.

## Current implementation and constraints

- Backend: Java 21, Spring Boot 4.1.0, Spring Security OAuth2/OIDC, JDBC and Flyway.
- `auth/SecurityConfig` registers Google login, directs anonymous navigations to Google,
  and applies `prompt=select_account` through a common authorization resolver. Scope
  that parameter to Google when introducing Apple; send anonymous navigation to the
  provider chooser instead of forcing Google.
- `SignupOidcUserService` assumes Google, verified email and `sub` as the app user ID.
- `SecurityContextCurrentUser` returns the OIDC subject directly. `CurrentUser` documents
  that subject as a Google ID. Broker credentials, sessions, connection identifiers and
  snapshots rely on that ownership key.
- `AppUserRepository` and V9 use `app_user.user_id` as the stable identity. Preserve all
  existing values; do not rewrite broker data or re-encrypt credentials for this feature.
- Web sessions are persisted in Postgres (V11). Session cookie is SameSite=Lax, HttpOnly,
  and Secure in production. CSRF uses the separate XSRF-TOKEN cookie.
- `/api/me` returns email, name and picture; the frontend expects an OIDC-backed profile.
- Vite and Caddy already proxy `/oauth2` and `/login/oauth2`; verify Apple callback POST
  routing rather than assuming a new proxy path is required.

## Agreed scope and decisions

Implement ordinary Apple signup/login with separate accounts per provider identity.
Do not offer linking, merging, unlinking or a matching-email prompt in the first release.
Explain that choosing Apple does not open an existing Google account or copy its broker
registrations. Apple relay email is a valid contact address, not an ownership key.

Future owner-requested flow: when verified emails match, offer the authenticated user a
prompt asking whether they want to merge. Matching email is only a discovery hint; acceptance
must lead to authentication of both accounts and explicit confirmation of the resulting
account/data changes. Do not expose the other account's broker data or enable public email
enumeration. Specify conflicts, retained user ID, credentials, sessions, terms and audit
history before implementing a merge. Hide My Email may prevent a match, so a manual path
will need separate design. No future merge is performed automatically.

Keep legacy Google subjects as existing internal user IDs. Generate opaque internal IDs
for new accounts and resolve every external identity through a mapping. External token
subjects stay intact; do not replace a provider's `sub` claim with an internal ID.

## AP-1 — Apple prerequisites and protocol proof

1. Confirm access to an eligible Apple Developer team and its Sign in with Apple-enabled
   primary App ID. Register and associate a Services ID for the website; confirm Apple's
   requirements for this web-only product before committing to delivery.
2. Register exact HTTPS domain callback URLs, proposed as
   `https://goldenbook.in/login/oauth2/code/apple` and a separately configured staging URL.
   Apple does not accept localhost or IP-address return URLs. Use staging or an explicitly
   configured HTTPS development domain for live checks; no local dev-auth bypass in staging.
3. Create the private key and record Team ID, Key ID and Services ID. Store the key outside
   git, frontend bundles and the database. Proposed configuration: `GB_APPLE_ENABLED`,
   `GB_APPLE_TEAM_ID`, `GB_APPLE_KEY_ID`, `GB_APPLE_CLIENT_ID`, `GB_APPLE_PRIVATE_KEY_FILE`.
   Register the provider only when enabled; disabled must require no Apple credentials.
4. Prove authorization-code flow, actual claims and Spring Security compatibility against
   Apple. Apple-specific integration must not assume a Google-style UserInfo endpoint.
   Use verified identity-token claims and separately validated optional first-login profile
   data. Normalize Apple claim representations deliberately, including email verification.
5. Generate the ES256-signed client-secret JWT server-side with bounded validity and renewal
   before expiration; verify Apple's current maximum lifetime at implementation time.
   Test signing and rotation with a fixed Clock. Never log secrets or callback bodies.

Acceptance: documented non-secret Apple registration details, actual claim/error shapes,
successful HTTPS callback proof, and a confirmed secure correlation design for AP-3.

## AP-2 — Provider-independent internal identity

1. Add an additive Flyway migration (choose the next free version at implementation time)
   for `auth_identity`: provider, issuer, subject, internal user_id, verified contact/profile
   metadata as needed, and creation/last-login timestamps. Enforce uniqueness on
   `(provider, issuer, subject)` and reference `app_user`. Do not use email as a key.
2. Backfill Google mappings for existing app users, using the verified Google issuer
   convention from our configured provider. Inventory legacy/dev rows before the backfill;
   do not fabricate real provider identities for synthetic dev users.
3. Resolve the authenticated provider identity to an internal user ID before admission and
   before any user-scoped service is called. Handle concurrent first login atomically so
   one external identity cannot create two app users. New users receive opaque IDs.
   A new Apple identity must create a distinct account even if its verified email matches
   a Google user's email; audit email-based privilege checks to prevent inherited access.
4. Update `CurrentUser`, signup policy and account-status checks to use internal identity.
   Audit direct `getSubject()`, principal names, admin-email checks, broker ownership,
   connection ID parsing, terms acceptance and deletion paths for Google assumptions.
5. Preserve profile information when Apple omits it on subsequent logins. Keep provider
   contact emails separate from app account ownership. Explicitly define allowlist behavior:
   Apple signup uses its verified address and its own account's status, without bypassing
   deployment admission rules. Never invent verified email/profile.
6. Define session compatibility for persisted Google principals: resolve legacy sessions
   through their Google mapping or deliberately expire them at rollout. Test and document
   the selected behavior. Preserve dev auth with its configured internal ownership ID.

Acceptance: existing Google users retain identical credentials, connection IDs and snapshots;
equal subject strings from different providers cannot collide; disabled/closed/allowlist
policies and dev auth retain their intended behavior. Run real Postgres migration tests.

## AP-3 — Apple callback and session security

Apple's profile-scoped flow uses `response_mode=form_post`. A cross-site POST normally
does not carry our SameSite=Lax session cookie. Standard session-only OAuth request storage
therefore needs a deliberate adaptation; allowing a callback URL is insufficient.

1. Prototype and select browser-bound correlation before wiring signup. Preferred direction:
   a short-lived Secure, HttpOnly, SameSite=None correlation cookie and server-side pending
   authorization record, containing hashed random state, nonce and expiry. Bind the
   initiating browser. Do not weaken the main session cookie globally.
2. Implement login/signup only. Never attach Apple to the currently signed-in Google user
   merely because a session or matching email exists. Require an intentional sign-out/login
   transition when changing accounts; clear user-specific frontend caches on that transition.
   Rotate the application session on successful login and check the target account's status.
3. Validate state, nonce, issuer, audience, token signature, expiry and single-use code.
   Support signing-key rotation. Consume pending state atomically; reject replay, mismatch,
   unsolicited callbacks and concurrent replay. Permit only configured same-origin completion URLs.
4. Exempt only the exact Apple POST callback from ordinary cookie-based CSRF validation;
   the OAuth correlation checks replace it there. Retain CSRF protection on other mutations.
   Bound callback size, sanitize first-login names and redact all provider payloads from logs.
5. Handle cancel, access denial, missing optional name/picture, missing required identity
   claims, token endpoint failure and database failure with bounded user-facing errors.
   Clear temporary correlation state/cookies on completion and expiry.

Acceptance: real browser tests across the cross-site POST boundary, including parallel tabs,
restart, missing cookies, callback replay, session expiry and malicious callback injection.
Google login/logout and broker callbacks must keep working.

## AP-4 — Frontend and account lifecycle

1. Add the Apple button to `LoginPage` and any other signup entry points, following Apple's
   branding requirements. Drive visibility from backend provider availability so the frontend
   cannot advertise a disabled provider. Preserve Google and local development behavior.
2. Explain that Google and Apple open separate GoldenBook accounts, with separate broker
   setup and data. Do not add a Link Apple action or merge prompt in this release.
3. Keep `/api/me` compatible where possible; update `src/types/api.ts` with any explicit
   provider-status APIs. Make display of name/picture resilient to Apple's missing fields.
4. Record terms acceptance against the internal account. Update privacy, support and erasure
   documentation for Apple identity data and any retained provider tokens.
5. Define and implement Apple token revocation/account-deletion lifecycle before enabling
   public signup. Retain only the encrypted provider token needed for that lifecycle, with
   clear retention and key handling; distinguish provider authorization withdrawal from
   a user-requested complete GoldenBook deletion. Handle Apple's server notifications where
   required by the chosen integration, including consent revocation and account deletion.
6. If transactional email is added, configure Apple's private email relay sender requirements;
   email delivery is not necessary for the current login-only scope.

Acceptance: new Apple user, returning user with no repeated profile payload, Hide My Email,
same-email separate accounts, account switching, cancel/error, logout, midnight expiry and
deletion/revocation have specified and verified outcomes on desktop and phone.

## AP-5 — Verification and release

- Unit/HTTP tests: JWT signing, token validation and key rotation, provider-specific request
  parameters, profile handling, safe errors and logging. Use synthetic identities and clocks.
- Database tests: additive backfill, legacy ownership preservation, concurrent signup
  uniqueness, same-email account separation, disabled accounts, deletion and transaction rollback.
- Browser tests: real Apple HTTPS POST callback correlation plus mocked adverse outcomes;
  Google regression; persisted session restart; two-user isolation on every broker API.
- Checks: backend `.\mvnw.cmd clean test`; opt in to database-tagged tests using the actual
  POM exclusion override (`-DexcludedGroups=`) with the required database test runtime.
  Frontend `npm test` and `npm run build`; documentation `git diff --check` and link review.
- Deploy identity foundation with Apple disabled, verify Google with existing accounts, then
  enable Apple on staging and certify with real Apple accounts. Enable production only after
  the migration, browser and lifecycle gates pass and deployment is explicitly requested.
- Rollback starts by disabling Apple; Google and existing ownership mappings must remain
  usable. Keep additive identity data. Establish the oldest compatible backend version before
  release; an old backend does not understand Apple-only users or newly serialized principals.
- Observe provider success/failure counts, latency and expired-secret warnings without
  emails, subjects, codes, raw tokens or credentials in logs. Provide a key-rotation runbook.

Done means both providers work under the existing admission policies, Google and Apple accounts
remain separate even with matching email, recovery/deletion paths work, and real HTTPS browser
verification passes. Code completion alone is not release certification.

## Inputs needed before implementation

- Apple Developer team availability and primary App ID eligibility.
- Account policy is decided: separate accounts now; optional authenticated merge prompt later.
- Selected staging/development HTTPS callback domains and key custody.
- Decision on whether Apple support belongs before or after the existing launch gates.

These are implementation inputs, not blockers to writing this plan. No registration, secret
creation, application changes, commit, push or deployment has been performed for this document.

## Official references

- [Configure the Apple environment](https://developer.apple.com/documentation/signinwithapple/configuring-your-environment-for-sign-in-with-apple)
- [Register a Services ID](https://developer.apple.com/help/account/identifiers/register-a-services-id/)
- [Create a private key](https://developer.apple.com/help/account/capabilities/create-a-sign-in-with-apple-private-key)
- [Authorization request and form-post response](https://developer.apple.com/documentation/signinwithapplerestapi/request-an-authorization-to-the-sign-in-with-apple-server.)
- [Token validation](https://developer.apple.com/documentation/SigninwithAppleRESTAPI/Generate-and-validate-tokens)
- [Sign in with Apple REST API and lifecycle endpoints](https://developer.apple.com/documentation/signinwithapplerestapi)

Check these sources again during implementation for protocol requirements and account setup.
