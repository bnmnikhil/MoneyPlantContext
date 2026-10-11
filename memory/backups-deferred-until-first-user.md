---
name: backups-deferred-until-first-user
description: Off-VM backups (N6/D1) deferred on 11 Oct 2026 until the first non-owner account registers a broker or before any announcement; strategy already fixed
metadata:
  type: project
---

**Decided 11 Oct 2026 (owner).** Production then held only the owner's data — 3 `app_user` rows (the owner's
accounts, one seeded by V9 from the owner's history, one throwaway sign-up), 4 broker credentials, 11 MB — all
recreatable. So N6 (off-VM backups, P0 D1) is **deferred, not dropped.**

**Trigger:** the first account that is not the owner's registers a broker, or any announcement or marketing,
whichever comes first. Sign-up is open, so the trigger can fire unannounced; watch `/app/admin`'s user count until
N9's monitoring can alert on new sign-ups.

**Why the strategy was fixed now anyway:** switching on should be an hour's work (the scripts exist, PR #16), not a
design session held under pressure when a real user's data is already at risk. Strategy: nightly encrypted
`pg_dump` to OCI Object Storage; 7 daily + 4 weekly; heartbeat alert (O3); monthly restore drill into staging.
Protect `GB_CREDENTIAL_KEY` first and never store it beside a dump; skip `broker_session` (expires daily).

**How to apply:** before telling anyone about GoldenBook, or on seeing a non-owner row in `app_user` with a
`broker_credential`, do N6 first. Detail in `NEXT-10.md` N6.
