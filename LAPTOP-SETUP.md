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
