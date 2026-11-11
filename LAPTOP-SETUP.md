# Laptop setup

How to rebuild this workspace on a fresh Windows install. Written 12 Oct 2026, before the
laptop was formatted. **No secrets live here; this repo is public.** Every secret named below
is kept in the owner's private backup, never in git.

## 1. Tools

- Git, Java 21, Node 24 (for the frontend and the docs build), Python with `requirements-docs.txt`
  (MkDocs, for `scripts/publish-docs.ps1`).
- **PostgreSQL 16 on port 5433:** `winget install PostgreSQL.PostgreSQL.16 --force` (the plain install
  403s partway through). Create role and database `goldenbook`, password `goldenbook`, owner
  `goldenbook`. PostgreSQL 17 was also installed on 5432 before, set to Manual; it is not needed.
- Docker is deliberately not used locally (`CLAUDE.md`, *Local development*).

## 2. Repositories

```
C:\Projects\Moneyplant\               bnmnikhil/MoneyPlantContext (this repo)
C:\Projects\Moneyplant\tradestack\    bnmnikhil/MoneyPlant
C:\Projects\Moneyplant\frontend\      bnmnikhil/MoneyPlantFrontend
C:\Projects\Moneyplant\broker-sim\    bnmnikhil/broker-sim
```

```
git clone https://github.com/bnmnikhil/MoneyPlantContext.git C:\Projects\Moneyplant
cd C:\Projects\Moneyplant
git clone https://github.com/bnmnikhil/MoneyPlant.git tradestack
git clone https://github.com/bnmnikhil/MoneyPlantFrontend.git frontend
git clone https://github.com/bnmnikhil/broker-sim.git broker-sim
cd frontend; npm install
```

**Layout actually used from 13 Oct to 9 Nov 2026** (the laptop was rebuilt that way; paths elsewhere in
this file, including the Claude settings below, still name the layout above — adjust them to whichever
you clone into). The workspace root `C:\projects\Goldenbook\` is a plain folder, not a repo, and holds
`.claude\settings.local.json`:

```
C:\projects\Goldenbook\MoneyPlantContext\    bnmnikhil/MoneyPlantContext
C:\projects\Goldenbook\MoneyPlant\           bnmnikhil/MoneyPlant
C:\projects\Goldenbook\MoneyPlantFrontend\   bnmnikhil/MoneyPlantFrontend
```

`broker-sim` was not cloned in that layout. Commits use the identity
`Nikhil <b.nikhilbabu1@gmail.com>`; set it on the new install (`git config --global user.name/user.email`)
before committing.

**Before the 9 Nov 2026 format, also back up** (private, never git): `C:\Users\<you>\.claude\projects\*\memory\`
(Claude's per-project memory, stored nowhere else) and `C:\projects\Goldenbook\artifacts\architecture\`
(architecture PDF, screenshots and their generator scripts; skip `tooling\node_modules`).

### Format of 12-13 Nov 2026

Everything in git was pushed first (all three repos; the local-only branches `feat/paytm-live-ticks` and
`plan/*` hold no commit that is not on GitHub). The private items were gathered into **one folder,
`GoldenBook-backup-2026-11-12`**, with a `README.txt` saying where each goes back: SSH keys, the `GB_*`
variables (`gb-env-backup.txt`), a dump of the local database (`goldenbook-local.dump`, which includes ITC and a
year of prices), Claude's memory and the workspace `.claude\settings.local.json`, the architecture artifacts, and
the 64 downloaded ITC filings (optional; only the backend's golden test reads them). Restore from that folder,
then:

- **Clone into the `C:\projects\Goldenbook\` layout** above. Branches to check out:
  - `MoneyPlant` and `MoneyPlantFrontend`: `main` (it carries the Research section since 11 Nov).
  - `MoneyPlantContext`: **`marketing/first-users`**. It holds the current `ANALYTICS-PLAN.md`, `BUSINESS-PLAN.md`
    and this file, and is not yet merged into `main`.
- **Research data on the new laptop:** either restore the database dump, or start empty and re-import ITC at
  `http://localhost:5173/app/admin/research` (owner only: start the backend with `GB_ADMIN_EMAILS` set to the dev
  address, `dev@localhost`, for that process). The NSE links lists are in this repo at
  `research/fundamentals-links/` (`ITC.txt`, `BSE.txt`).
- **Optional for the golden test:** put the 64 filings back at
  `MoneyPlantFrontend\scripts\fundamentals\cache\` (git-ignored). Without them `ItcGoldenFilingsTest` is skipped.
- **Docker is still not used locally;** the `db`-tagged tests run against local Postgres instead:
  `mvnw test -DexcludedGroups= -Dtest=FundamentalsStoreDbTest -Dfundamentals.db.url=jdbc:postgresql://localhost:5433/goldenbook`
  (a throwaway schema, dropped afterwards).
- The memory-capped way to run the backend on 8 GB is in Claude's memory (`laptop-git-and-tooling-gaps`):
  `mvnw -DskipTests package`, then `java -Xmx512m -XX:+UseSerialGC -jar target\tradestack-0.0.1-SNAPSHOT.jar`
  with the `GB_*` variables loaded.

**Not restored, by owner decision (12 Oct 2026):** the screener branches
`feat/index-spread-screener` in tradestack (`3e533ca`) and frontend (`abb378e`) were never pushed
and are dropped; the screener will be started fresh (`memory/index-spread-screener.md`).

## 3. From the private backup

| What | Put it back at |
|---|---|
| SSH keys, above all `vps.key` / `vps.pub` (the only way onto the VM for deploys) | `C:\Users\<you>\.ssh\` |
| User environment variables `GB_CREDENTIAL_KEY`, `GB_DB_URL`, `GB_DEV_AUTH`, `GB_DEV_USER_ID`, `GB_ALLOWED_EMAILS` | User environment (restore command below) |
| `Postman/` (Alice Blue collection and checksum script; may hold credentials) | `C:\Projects\Moneyplant\Postman\` (git-ignored) |
| Local database dump, if one was taken | `pg_restore` into `goldenbook` on port 5433 |

Restore the environment variables from a `NAME=value` backup file, then **open a new terminal**
(`setx` and this command only reach new processes):

```powershell
Get-Content .\gb-env-backup.txt | ForEach-Object {
  $name, $value = $_ -split '=', 2
  [Environment]::SetEnvironmentVariable($name, $value, 'User')
}
```

`GB_CREDENTIAL_KEY` must be the **same** key as before, or every broker credential in a restored
local database reads as `BROKER_CREDENTIAL_UNREADABLE`. With a fresh, empty database any new
32-byte base64 key works. `GB_DEV_USER_ID` is the Google `sub` the local credentials are keyed to.
The backend refuses to start while any old `MP_*` variable is set.

## 4. Claude Code permission settings

Claude Code reads these from git-ignored files, so they are recorded here to copy back.

`C:\Projects\Moneyplant\.claude\settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(./mvnw -q -o test)",
      "PowerShell(try { $r = Invoke-WebRequest -Uri \"http://localhost:8080/api/session/status\" -UseBasicParsing -TimeoutSec 5; Write-Output \"UP: $\\($r.Content\\)\" } catch { Write-Output \"DOWN: $\\($_.Exception.Message\\)\" })",
      "PowerShell(try { $r = Invoke-WebRequest -Uri \"http://localhost:8080/paytm/debug/spot?underlying=BANKNIFTY\" -UseBasicParsing -TimeoutSec 30; $r.Content } catch { Write-Output \"ERR $\\($_.Exception.Message\\)\"; if \\($_.Exception.Response\\) { \\(New-Object System.IO.StreamReader\\($_.Exception.Response.GetResponseStream\\(\\)\\)\\).ReadToEnd\\(\\) } })",
      "Bash(echo \"exit=$?\")",
      "Bash(npm run *)",
      "PowerShell(Get-CimInstance *)",
      "Bash(./mvnw -o test -Dtest=PaytmSecurityMasterTest)",
      "Bash(./mvnw -o test)",
      "Bash(./mvnw -o test -Dtest=FileSessionStoreTest)",
      "Bash(grep -E \"Tests run:.*Failures.*Errors.*Skipped$\")",
      "Bash(./mvnw -o test -Dtest=SessionStoreConfigTest)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git push *)",
      "Bash(git rev-list *)",
      "Bash(git checkout *)",
      "Bash(./mvnw -q dependency:resolve -DincludeScope=test)",
      "Bash(echo \"EXIT=$?\")",
      "Bash(./mvnw -q dependency:tree -Dincludes=org.springframework.security)",
      "Bash(./mvnw dependency:tree -Dincludes=org.springframework.security)",
      "Bash(./mvnw test *)",
      "Bash(git -C frontend branch --show-current)",
      "Bash(git -C tradestack branch --show-current)",
      "PowerShell(foreach \\($p in 5173,8080\\) { $r = Test-NetConnection -ComputerName localhost -Port $p -InformationLevel Quiet -WarningAction SilentlyContinue; \"$p listening=$r\" })",
      "PowerShell(git *)",
      "Bash(xargs -I{} sh -c 'echo \"--- {}\"; grep -n \"Mapping\\(\" {}')",
      "Bash(ssh -i ~/.ssh/vps.key ubuntu@140.245.250.217 \"sudo -u gbstaging /opt/goldenbook-staging/src/tradestack/deploy/staging/deploy-staging.sh *\")"
    ]
  },
  "outputStyle": "default"
}
```

The last rule lets Claude deploy **staging** without asking. Production deploys and every other
command on the VM still ask each time, by design.

`C:\Projects\Moneyplant\frontend\.claude\settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Read(//c/Projects/Moneyplant/tradestack/**)",
      "Bash(./mvnw -q test)",
      "Bash(npm run *)",
      "Bash(git rev-list *)"
    ]
  }
}
```

Claude's per-user memory (`C:\Users\<you>\.claude\projects\C--Projects-Moneyplant\memory\`) held only
two pointers; the project memory is `memory/` in this repo.

## 5. Check it works

```
cd tradestack; ./mvnw clean test          # the Results: line is the only real count
cd ../frontend; npm run typecheck; npm test; npm run build
```

Then start the backend with dev auth (`GB_DEV_AUTH=true`) and the frontend (`npm run dev`), and open
`http://localhost:5173/app`. A deploy to staging confirms the SSH key:
`ssh -i ~/.ssh/vps.key ubuntu@140.245.250.217 "sudo -u gbstaging /opt/goldenbook-staging/src/tradestack/deploy/staging/deploy-staging.sh main"`.
