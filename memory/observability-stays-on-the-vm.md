---
name: observability-stays-on-the-vm
description: Logs, metrics and crash reports stay on the OCI VM; external services get only pings and counts; alerts go to a private Telegram bot.
metadata:
  type: decision
---

**Decided 2 Oct 2026 (owner)**, while planning monitoring for the public launch
([[public-launch-is-open-signup]]). The plan and its O-items are in `OBSERVABILITY.md`.

**The rule: nothing personal leaves the VM.** The privacy policy written the same day
names its processors: Google, the brokers, OCI, Cloudflare DNS and Google Fonts. A hosted
log or error service would be a new processor, a policy change, and somewhere for request
ids, Google subs and stack traces to accumulate outside our control. So:

- **Metrics are self-hosted.** Prometheus + Grafana + node_exporter run in the existing
  `docker-compose.yml`, bound to loopback and reached over an SSH tunnel. Rejected:
  Grafana Cloud's free tier. Less ops work, but it is a new processor, and the 24 GB
  free-tier VM can afford ~0.6 GB.
- **Frontend crash reports are self-built**, posted to our own `/api/client-errors`.
  Rejected: Sentry, because it is a third-party script plus a processor. Wanted **at
  launch**: strangers do not file bug reports, so a broken page would otherwise be invisible.
- **Alerts go to a private Telegram bot**, and its messages carry only counts and request
  ids. Rejected: email (missed during market hours) and ntfy (fewer native integrations).
  If an alert ever includes user data, Telegram becomes a processor and the policy must say so.
- The only external monitors are UptimeRobot and Healthchecks.io, and they receive pings.

**Two rules follow, and code review should enforce them.** Metric tags never carry
`userId` or `connectionId`; that is a cardinality rule and a privacy rule at once. And
logs never carry secrets, tokens, emails or rupee amounts (the old `MarginAllocator`
"estimate vs bill" INFO line did, which is why it becomes a metric).
