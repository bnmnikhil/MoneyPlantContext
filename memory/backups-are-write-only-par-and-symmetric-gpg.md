---
name: backups-are-write-only-par-and-symmetric-gpg
description: "Backups upload through a write-only OCI pre-authenticated request and are sealed with symmetric gpg; the restore test, not the timer, is what makes them real"
metadata:
  type: decision
---

Decided 20 Aug 2026, doing **D1** in `P0-LAUNCH.md` — the first P0 item, and one
of the two findings that outranked the original checklist. Before this there
were no backups of anything: no `pg_dump`, no schedule, no off-VM copy, no
tested restore, with every user's encrypted broker credentials in exactly one
Docker volume.

## Three choices, and what each one costs

**A write-only pre-authenticated request, not the OCI CLI.** The PAR is scoped
`Permit object writes` with listing disabled, so the VM can create backups but
cannot read, list or delete them. A compromised host therefore cannot exfiltrate
the backup history or destroy it, which is most of what an off-site backup is
for — and it needs no CLI, no python on an arm64 free-tier box, and no API
signing key at rest. **The costs are real and both show up later:** retention has
to be a bucket lifecycle rule because the VM cannot delete, and verifying an
uploaded object needs a *second*, read-only PAR that is deliberately not kept on
the machine. Accept both; they are the price of the property.

**Symmetric gpg, not a public key.** Asymmetric sounds strictly better — the VM
would hold only a public key and could not decrypt its own backups. It is not,
here. Anything that can read the passphrase off this host can already read
`MP_CREDENTIAL_KEY` and the database password out of
`/etc/moneyplant/moneyplant.env`, which is **strictly more than the backup
holds**. So asymmetric buys nothing against the realistic threat and costs a
second unrecoverable secret to lose. The threats it does defend against — the
object at rest in Object Storage, an OCI account compromise, a stray copy of the
file — are covered either way. If the VM ever stops holding the credential key,
revisit this.

**Refuse to upload a dump with no `broker_credential` table data.** The failure
this whole item exists to prevent is not a backup that errors. It is one that
uploads cleanly, keeps the timer green, and is empty — the same shape as the
`[x]`-on-the-strength-of-the-code-looking-right failure the tracker's status
legend was written against. `backup.sh` greps the archive TOC before calling it
a backup, and `restore-verify.sh` treats a restore with zero credential rows as
a failure rather than a pass.

## The restore test is the item; the timer is not

**Two secrets have to survive the VM and only one of them is in the dump.**
`MP_CREDENTIAL_KEY` is deliberately not in the database (see
[[credentials-per-user-per-registration]]), so a restore without it yields a
table of unreadable bytes and the only recovery is every user re-entering their
broker credentials. `MP_BACKUP_PASSPHRASE` opens the file itself. A verification
that reads the key out of the live env file proves the VM agrees with itself,
which is not the question — so `restore-verify.sh` requires the key to be pasted
in from the off-VM copy, and compares it to the live one by digest without ever
printing either.

`deploy/CredentialDecryptCheck.java` does the decrypt as a Java 21 single-file
program rather than by booting the app, because the check has to run against the
*scratch* database with the *backed-up* key; the app would use neither. It never
prints a plaintext — these are live brokerage secrets, and a verification you run
on a terminal must not be the thing that leaks one into scrollback.

## What the rehearsal caught

Rehearsed end to end against the local Postgres before any of it went near the
VM: dump, emptiness guard, gpg seal and open, restore into a scratch database,
row counts, Flyway history, and all four real credential rows decrypting under
the live key while a random key failed all four.

That found one bug nothing else would have. **Postgres's
`encode(bytea,'base64')` wraps its output at 76 characters**, so a ciphertext
longer than that arrived split across two lines, every row after it shifted, and
the check reported three spurious failures out of six — a verification tool
confidently reporting that good backups were bad. The extraction is `encode(...,
'hex')` now, which never wraps. Same family as
[[an-unmeasured-zero-is-a-claim]]: the output was wrong in a way that read as a
finding.

## It is silent when it stops

A backup that quietly stopped running looks exactly like one that is working.
`backup.sh --check` exits non-zero when the last success is older than 36 hours
and exists to be the command **D2**'s monitor calls; `moneyplant-backup.service`
carries a commented `OnFailure=` line for the same hook. Until D2 lands,
`systemctl list-timers` is the whole story, and that is a known gap rather than
an oversight.
