# Observability: logs, metrics, alerts

**Created 2 Oct 2026.** The plan for knowing what GoldenBook is doing once strangers use it.
It expands P0 item **D2** ("no health endpoint, no monitoring") into **O-items**, tiered
against the public launch (`PUBLIC-LAUNCH.md`), which carries the schedule. Status markers
and the `[x]`-only-after-verification rule are the same as `P0-LAUNCH.md`'s. Branch names
carry the id (`launch/o1-health`).

## Where it stands (read off `origin/main`, 2 Oct)

| Area | Today |
|---|---|
| Health | **None.** No actuator in the pom. `deploy.sh`'s readiness probe curls `/api/me` and is itself broken (D3). |
| Metrics | **None.** No Micrometer, no Prometheus, no host metrics. |
| Logs | Plain-text Logback to stdout → journald (`SyslogIdentifier=goldenbook`). No logging config at all. 16 debug, 19 info, 44 warn and 2 error statements. **No request id or MDC**, so one user's request cannot be followed through the log. |
| Errors | Nothing catches unexpected exceptions (B6); they reach Spring's default handler. Frontend errors are invisible: no error boundary (B2), no reporting. |
| Alerting | **None.** `backup.sh --check` exists to be called by a monitor that does not exist. |
| Retention | **Breaks the privacy policy's "server logs ≤ 30 days".** journald is capped by size, not age. Caddy's file log uses Caddy's defaults (by default `roll_keep_for` is 90 days). Docker's `json-file` driver for Postgres never rotates. |
| Log content | `MarginAllocator:193` writes `connection=` (it contains the Google sub) plus rupee estimate and bill at **INFO, on every risk request**. That is portfolio data in a log file. Caddy writes callback query strings, which carry broker request tokens (C2). |
| JVM | No `-Xmx`, no out-of-memory policy. The local crash dumps (`hs_err_pid*.log`) show it does crash. |

## Constraints that shape every choice

1. **Nothing personal leaves the VM.** The privacy policy names Google, the brokers, OCI,
   Cloudflare DNS and Google Fonts as the only processors. A hosted log or error service
   (Grafana Cloud, Sentry, Better Stack logs) means a policy change and a new processor, so
   it is avoided. External services get **pings and counts only**.
2. **One person, one VM, free tier.** Prefer what Spring Boot and systemd already provide.
   Anything self-hosted binds to `127.0.0.1` and is reached over an SSH tunnel, never published.
3. **A broker outage is not our outage.** `CALL_FAILED` spikes for one vendor should
   *notify*, not page. Pages are for things only the operator can fix.
4. **Market hours matter more than nights.** 09:15–15:30 IST is when a wrong or missing
   number costs a user money.
5. **Metric tags never carry `userId` or `connectionId`.** That is a cardinality rule *and*
   a privacy rule. Per-user questions are answered from logs (30 days) or the database.

## Stack, decided 2 Oct 2026 (owner)

Telegram for alerts, metrics self-hosted on the VM, and self-built frontend crash reports **at launch** (so O13 is Tier 1). Reasoning is in `memory/observability-stays-on-the-vm.md`.

| Need | Choice | Why |
|---|---|---|
| Is the site up? | **UptimeRobot** (free), checking the public URL and `/api/health` every 5 min | It must sit *outside* the VM, and it sees only a public URL |
| Did the scheduled job run? | **Healthchecks.io** (free) dead-man switches | Backup and EOD capture each ping on success; silence pages. Fits `backup.sh --check` exactly |
| Alerts to a phone | **A private Telegram bot** | Both services above integrate natively, and so does Grafana alerting. Messages carry counts and request ids, never user data |
| Metrics | **Actuator + Micrometer → Prometheus + Grafana**, self-hosted in the existing `docker-compose.yml`, loopback only | Data stays on OCI. About 0.5–0.7 GB RAM, which is comfortable after L13's free resize to 24 GB |
| Host metrics | `node_exporter` (loopback) | Disk is the likeliest VM-killer while `raw_capture` has no retention (L14) |
| Logs | **journald, structured JSON**, 30-day retention, queried with `journalctl -o cat \| jq` | Already there. Loki is deferred until journalctl stops being enough |
| Frontend errors | `POST /api/client-errors` from the error boundary, rate-limited, logged with the request id | No third-party script, and no change to the cookie statement |

Re-check each free tier's limits when signing up; they change.

---

## Summary

| ID | Item | Tier | Status |
|---|---|---|---|
| O1 | Health endpoint: actuator, liveness + readiness, a public minimal `/api/health` | 1 | `[ ]` |
| O2 | External uptime + Telegram alert channel | 1 | `[ ]` |
| O3 | Heartbeats: backup and EOD capture → Healthchecks.io | 1 | `[ ]` |
| O4 | Log retention ≤ 30 days everywhere (journald, Caddy, Docker) | 1 | `[~]` |
| O5 | Request id end to end: Caddy → MDC → B6 error body → UI "reference" | 1 | `[ ]` |
| O6 | Structured JSON logs + log hygiene rules (no secrets, tokens, emails or rupee amounts) | 1 | `[ ]` |
| O7 | JVM flags: heap, exit on OOM, crash dumps out of the app dir; restart is alerted | 1 | `[ ]` |
| O8 | Audit events for security-relevant actions | 1 | `[ ]` |
| O9 | Micrometer metrics: built-ins + the GoldenBook catalogue below | 2 | `[ ]` |
| O10 | Prometheus + Grafana + node_exporter on the VM, loopback only | 2 | `[ ]` |
| O11 | Three dashboards: Overview, Brokers, Host | 2 | `[ ]` |
| O12 | Alert rules: page vs notify vs daily digest, market-hours aware | 2 | `[ ]` |
| O13 | Frontend error reporting (`/api/client-errors`), rides on B2 | **1** (owner, 2 Oct) | `[ ]` |
| O14 | Ops runbook: journalctl/jq queries, the tunnel, what each alert means | 2 | `[ ]` |
| O15 | Loki, if journalctl is not enough after a month | 3 | `[ ]` |
| O16 | SLOs, set from a month of real data, not guessed now | 3 | `[ ]` |
| O17 | Product numbers (users, connections, daily active) as a DB view, no tracking | 3 | `[ ]` |

**Tier 1 is the launch floor (O1–O8, plus O13 by owner decision):** you find out the site is down before a user tells you,
and every promise in the privacy policy about logs is true. It replaces D2 in
`PUBLIC-LAUNCH.md`'s Tier 1. O13 needs only B2 and O5, not the Tier 2 metrics stack. Its counter waits for O9; until then the log line is the record. Tier 2 is launch week. Tier 3 waits for a month of data.

---

## Tier 1 — the launch floor

### `[ ]` O1 — Health endpoint

**Do:** add `spring-boot-starter-actuator`. Run the management port on `127.0.0.1:8081`
(`management.server.port`, `management.server.address`), exposing `health` and
`prometheus` (the latter for O10). Enable the liveness and readiness probe groups;
readiness includes the DB. Publicly, add **`GET /api/health` → `{"status":"UP"}`** only:
no components, no versions, permitted without auth. That is what UptimeRobot hits. Point
`deploy.sh`'s readiness loop at the loopback readiness probe; this fixes D3 for free.
**Never** let broker reachability into health: a Paytm outage must not mark GoldenBook DOWN.

**Verify:** `curl 127.0.0.1:8081/actuator/health/readiness` returns UP, and DOWN with
Postgres stopped. The public `/api/health` carries no detail. `:8081` is unreachable from
outside the VM.

### `[ ]` O2 — External uptime and the alert channel

**Do:** create a Telegram bot and a private chat, and keep the token in the password
manager. Add two UptimeRobot monitors, the site root and `/api/health`, alerting to
Telegram after two consecutive failures.

**Verify:** `systemctl stop goldenbook` pages the phone within 10 minutes, and recovery
is announced too.

### `[ ]` O3 — Heartbeats for scheduled work

**Do:** one Healthchecks.io check each for `goldenbook-backup` (period 24 h, grace 12 h,
matching `backup.sh --check`'s 36 h) and the EOD capture job. On success, the backup unit
runs `curl -fsS -m 10 --retry 3 https://hc-ping.com/<uuid>`, and the commented
`OnFailure=` line gets used. The EOD job pings from Java on success, with the URL in the env file.

**Verify:** disable the timer, and the miss is reported once the grace period runs out.

### `[~]` O4 — Retention: make the privacy policy true

**Implemented 3 Oct 2026 on `launch/o4-c2-log-retention`; not yet applied on the VM.**
The plan below was changed in one respect: **every limit is an age, not a size.** Caddy
rolls files by size only and Docker's `json-file` options cap bytes, so at this traffic
either could keep months of lines. Instead, everything that can hold user data goes to
the journal, and one age limit covers it:
- journald `MaxRetentionSec=28day` + `MaxFileSec=1day` (an entry outlives the limit by at
  most one file's span), `SystemMaxUse=2G` as a disk ceiling only.
- Caddy `output stderr` → journal. Postgres → Docker's `journald` driver, tag
  `goldenbook-postgres`.
- New finding: Ubuntu's rsyslog copies the journal into `/var/log/syslog`, kept about five
  weeks. `rsyslog-goldenbook.conf` stops that copy for goldenbook*/caddy only.
- C2 strips **every** query string (`/path?redacted`) rather than named parameters, and
  drops the Referer: Google's callback carries an auth code, and API calls carry
  `connectionId` (the Google sub). Proven on Caddy 2.11.6 locally with planted tokens.

Apply and verification commands are in `tradestack/deploy/README.md` under "Logs". Flip
to `[x]` once that verification has run on the VM.

**Original plan:**

**Do:**
- journald: `/etc/systemd/journald.conf.d/goldenbook.conf` with `MaxRetentionSec=30day`
  and `SystemMaxUse=2G`.
- Caddy: inside `log { output file … { roll_keep_for 720h  roll_size 50MiB } }`. In the same
  edit, fix C2 by stripping the query string. `log_skip` the callback routes, or filter
  `request>uri` with Caddy's `query` filter (delete `request_token`, `code`, `state`, `auth_code`).
- Docker: `logging: { driver: json-file, options: { max-size: 10m, max-file: "3" } }` on
  the Postgres service.

**Verify:** `journalctl --header`, the Caddy log directory, and `docker inspect` each
show the limits. After a broker connect, grep the Caddy log for the request token and
find nothing.

### `[ ]` O5 — One request id, end to end

**Do:** in Caddy, `request_header X-Request-Id {http.request.uuid}`, and copy it into
the response header. In the app, a servlet filter reads it (or mints one locally), puts
it and the pseudonymous `user` (the Google sub, never the email) in the MDC, and clears
both in `finally`. B6's catch-all returns `{error, message, requestId}`. The frontend's
`ErrorState` shows "Reference: abc123" so a support email arrives with the key to the log.

**Verify:** force an exception. The UI reference, the response header and the log line
all carry the same id.

### `[ ]` O6 — Structured logs and what may be in them

**Do:** `logging.structured.format.console=ecs` (built into Spring Boot since 3.4).
journald then holds one JSON object per line, with MDC fields included. Then apply the
rules:
- **Never:** secrets, access or request tokens, emails, broker client codes, rupee
  amounts, raw broker payloads.
- **User reference:** the sub from MDC only, never in the message text.
- **Levels:** `ERROR` means a human should look, because O12 alerts on its rate. `WARN`
  means expected-but-notable, such as a vendor failure. Per-request chatter goes to `DEBUG`.

Concrete fixes: `MarginAllocator:193` drops the rupee figures (the ratio becomes an O9
metric), and the `user={}` placeholders in the `snapshot/` warnings move to MDC.

**Verify:** a grep of a day's journal for `@`, `token`, `secret` and `₹`/amount-shaped
numbers finds nothing. One request's lines are retrievable by id with
`journalctl -u goldenbook -o cat | jq 'select(.requestId=="…")'`.

### `[ ]` O7 — JVM behaviour under failure

**Do:** in `goldenbook.service`: `-Xms512m -Xmx2g` (revisit after L13),
`-XX:+ExitOnOutOfMemoryError` (a dead JVM restarts clean, instead of limping on),
`-XX:ErrorFile=/var/log/goldenbook/hs_err_%p.log` and
`-Xlog:gc*:file=/var/log/goldenbook/gc.log:time:filecount=5,filesize=10m`. Add the log
dir to `ReadWritePaths`. Alerting on a restart arrives with O12. Until then,
`systemctl status` shows the restart count. While editing the unit, also fix D5's stale
`GB_SESSION_STORE` comment there.

**Verify:** a deliberate OOM in a dev profile restarts the service, and the crash file
lands in `/var/log/goldenbook`.

### `[ ]` O8 — Audit events

Needed for a breach investigation and for answering "did someone else use my account?".
**Do:** a dedicated `AUDIT` logger with structured fields, recording: sign-in success
and refusal (with reason); terms accepted (L4); credential saved and deleted; broker
connected and disconnected (C5); account erased (E3); sign-up mode changed and user
disabled (L3). It inherits the 30-day journald retention. Longer retention would need a
table **and** a privacy-policy line, so it is deliberately not done now.

**Verify:** each action produces exactly one `AUDIT` line, with its request id.

---

## Tier 2 — launch week

### `[ ]` O9 — Metrics catalogue

The built-ins arrive with actuator and `micrometer-registry-prometheus`:
`http.server.requests` (URI *templates*, so `/api/payoff/{underlying}` stays one series),
JVM memory/GC/threads, `hikaricp.*`, `process.uptime`, and **`logback.events{level}`**.
The last one is how O12 alerts on errors without shipping logs anywhere.

GoldenBook's own, with **tags limited to `broker`, `op` and `outcome`**:

| Metric | Type | Answers |
|---|---|---|
| `goldenbook.broker.calls{broker,op,outcome}` | timer | Is Kite slow or failing right now? (`outcome` = ok / session_expired / call_failed) |
| `goldenbook.broker.sessions{broker}` | gauge | How many live connections per broker |
| `goldenbook.instrument.master{broker,outcome}` | timer + age gauge | Did today's contract master load, and how stale is it (A3, B1) |
| `goldenbook.margin.estimate.ratio{broker}` | distribution | Estimate ÷ bill. Replaces the INFO log line in O6 |
| `goldenbook.signin{outcome}` | counter | ok / not_invited / disabled / terms_pending |
| `goldenbook.ratelimit.rejected{endpoint}` | counter | Is C4's limiter biting real users |
| `goldenbook.cache{cache,result}` | counter | Spot and chain cache hit rate (L18 changes the spot cache's shape) |
| `goldenbook.capture.runs{status}` | counter | EOD capture health |
| `goldenbook.db.bytes{table}` | gauge, refreshed every 15 min | `raw_capture` growth (L14), the disk forecast |
| `goldenbook.users{state}` | gauge, refreshed every 15 min | total / active today, from the DB, with no per-user tags |
| `goldenbook.client.errors` | counter | Frontend error rate (O13) |

**Verify:** `curl 127.0.0.1:8081/actuator/prometheus | grep goldenbook_` lists every row
above, and no series has a user or connection label.

### `[ ]` O10 — Prometheus, Grafana, node_exporter

**Do:** add three services to `deploy/docker-compose.yml`, each with a loopback-only
port and a memory limit. Prometheus scrapes `:8081` and `node_exporter` every 30 s, with
15-day retention. Grafana is reached with `ssh -L 3000:127.0.0.1:3000 vm`, and its admin
password goes in the password manager. Add the Prometheus volume to the D1 backup? **No.**
Metrics are disposable; say so in the runbook.

**Verify:** from outside, ports 3000, 9090 and 9100 refuse connections. Through the
tunnel, Grafana shows the app's series.

### `[ ]` O11 — Dashboards (provisioned as JSON in `deploy/grafana/`, not hand-built)

1. **Overview:** up/down, request rate, p95 latency per endpoint, 5xx rate, `ERROR`
   rate, sign-ins, active users today, restart markers.
2. **Brokers:** calls by outcome and p95 per broker, live sessions, contract-master age,
   margin-ratio distribution.
3. **Host:** CPU, memory, **disk and its 7-day forecast**, JVM heap and GC, Hikari pool,
   DB size by table.

### `[ ]` O12 — Alert rules

| Severity | Condition | Route |
|---|---|---|
| **Page** | Site or `/api/health` down twice running (O2) | Telegram, immediately |
| **Page** | `logback_events_total{level="error"}` rate > 5 in 5 min | Telegram |
| **Page** | Disk > 85%, or forecast full within 3 days | Telegram |
| **Page** | `process_uptime_seconds` < 300 (the service restarted) | Telegram |
| **Page** | Backup heartbeat missed (O3) | Telegram |
| Notify | One broker's `call_failed` > 50% for 10 min, **market hours only** | Telegram, muted 16:00–09:00 IST |
| Notify | Heap > 85% for 15 min; Hikari pending > 0 for 5 min; p95 `/api/positions` > 5 s for 10 min | Telegram, muted off-hours |
| Digest | Sign-ins, new users, error count, rate-limit rejections, margin ratio drift | One Telegram message at 18:00 IST |

**Verify:** fire each page condition deliberately once (stop the service, a test
endpoint that logs ERROR, `fallocate` a file to fill disk on a scratch mount), and watch
each one arrive.

### `[ ]` O13 — Frontend errors

**Do:** B2's boundaries and a `QueryCache.onError` sink POST to `/api/client-errors`
with `{message, stack (first 20 frames), route, appVersion}`, no query data. The endpoint
is authenticated, rate-limited at 10 per minute per user, logs at `WARN` with the request
id, and increments O9's counter. The build stamps `appVersion` (the git sha) so an error
maps to a commit.

**Verify:** a thrown render error shows up in the journal with its route and sha.

### `[ ]` O14 — Ops runbook

A section in `tradestack/deploy/README.md` covering: the tunnel, the ten journalctl/jq
queries that answer most questions (by request id, by user, errors in the last hour,
one broker's failures today, sign-in refusals), what each alert means and its first
three steps, and where O15/O16 would go next.

---

## Tier 3 — after a month of real traffic

- **O15 Loki.** Only if journalctl + jq becomes the bottleneck. Grafana Alloy ships the
  journal to it, with the same 30-day retention.
- **O16 SLOs.** Proposed shape: market-hours availability, and p95 for `/api/positions`
  *excluding* broker time. Set the numbers from O11's month of data.
- **O17 Product numbers.** A SQL view (users, connections per broker, daily active,
  retention), read through the tunnel. **No analytics script and no tracking cookie.**
  The privacy policy promises none.

## What changes elsewhere

- `PUBLIC-LAUNCH.md`: in Tier 1, D2 is replaced by O1–O8. The go/no-go items "stopping
  the service paged the owner's phone" and "server logs kept ≤ 30 days" are O2 and O4.
- Privacy policy: no change, as long as only pings and counts leave the VM. **If
  Telegram alert text ever includes user data, the policy must name Telegram.** Keep it
  to ids and counts.
- `MarginAllocator`'s ratio log line becomes a metric (O6 + O9), so the per-connection
  drift check it was written for moves to the Brokers dashboard.
