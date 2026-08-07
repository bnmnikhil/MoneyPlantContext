# IPv4 vs IPv6 for a broker-whitelisted static IP — support, cost, and where to buy

**Researched 6 Aug 2026.** Companion to `REGULATORY-API-STATIC-IP.md`, which establishes *when* a whitelisted static IP is required (order placement only, in force since 1 April 2026). This one answers the follow-ups: does the IPv6 path actually work end to end, what does each protocol cost, and where is the cheapest place to buy an address that can later be attached to a bigger VM.

**Reminder of scope:** MoneyPlant is read-only today and needs none of this for compliance. Everything below is either (a) present-day operational cost of running the VM, or (b) preparation for a decision that only becomes real if order placement is ever added.

---

## ▶ The short version

1. **IPv6 is free essentially everywhere; IPv4 is the line item.** IPv6 addresses carry no charge at OCI, AWS, Hetzner or Vultr. A public IPv4 costs $0–3.60/month depending on provider.
2. **But you cannot go IPv6-only for broker whitelisting, and the blocker is not the brokers — it is the last mile.** The chain has four links, and each one has to speak IPv6. In this project's case link 1 already fails: **the owner's home connection has no IPv6 egress at all** (measured, below).
3. **Broker support for IPv6 is real but not universal.** Zerodha accepts IPv6 in the whitelist field. **Kotak Neo is IPv4-only** and says IPv6 is "coming soon" — proof that "SEBI allows it" does not mean every broker implements it. Alice Blue and Paytm Money are unconfirmed.
4. **SEBI and NSE are protocol-agnostic** — the circulars say "static IP address(es)" and never name a version. So this is entirely a per-broker implementation question, not a regulatory one.
5. **The cheapest place to buy is the one already in use: OCI, at ₹0.** Reserved public IPv4 is free, IPv6 is free, the always-free VM includes a public IPv4, and a reserved public IP **can be moved to a different, larger instance in the same region** — which is exactly the "attach to a larger VM" requirement. Nothing on the market beats free, and the migration cost of leaving is real.
6. **One measured finding that outranks the cost question**: Zerodha rejects an IP already registered to another account, with the error `Each IP address can only be linked to one account.` That is NSE A.7 enforced in software. Multi-user order placement from one VM is not a plan that fails at review — it fails at the whitelist form.

---

## Does SEBI care which protocol?

No. The SEBI circular (4 Feb 2025) and NSE's implementation standards (NSE/INVG/67858) both say **"static IP address(es)"** throughout and never mention IPv4 or IPv6. The requirement is *stability and attributability* — one address, traceable to one person — and both protocols satisfy it equally.

Zerodha's own summary of the NSE framework states IPv4 and IPv6 are both acceptable. So the regulator permits IPv6; whether you can *use* it is decided entirely by your broker's console and by your network path.

## Does every broker support IPv6?

**No.** This is the answer to the direct question, and the variation is wide.

| Broker | IPv6 in whitelist | Basis | Confidence |
|---|---|---|---|
| **Zerodha / Kite Connect** | **Yes** | Support docs and forum; both families accepted in the developer console profile | High |
| **Kotak Neo** | **No — IPv4 only** | Their static IP page states "IPv4 (currently), IPv6 support coming soon" | High |
| **Alice Blue** | Probably — reported alongside other Noren-OMS brokers as IPv4/IPv6 ready | Third-party guide only; no Alice Blue statement found | **Low** |
| **Paytm Money** | Unknown | Nothing published; not even the IPv4 rules are documented | **None** |

Kotak Neo is the useful data point even though this project does not use it: it demonstrates that a broker can be fully compliant while accepting IPv4 only. **Design for IPv4 and treat IPv6 as a bonus**, because the moment one of your brokers is IPv4-only, an IPv6-only host cannot serve that broker at all.

### The trap Zerodha specifically warns about

If you whitelist an IPv6 address but your request egresses over IPv4 — or the reverse — validation fails. Dual-stack hosts make this a coin toss: most clients prefer IPv6 when an AAAA record exists (Happy Eyeballs), so a dual-stack VM with only its IPv4 whitelisted will silently start failing the moment IPv6 works. **Whitelist what actually leaves the box, and if the host is dual-stack, register both** (as primary and secondary) or pin the client to one family.

## The four links that all have to speak IPv6

Broker support is only one of them. For an IPv6 whitelist to work end to end:

1. **Your egress network** must have IPv6 — home ISP, or the VM's provider.
2. **The broker's API endpoint** must be reachable over IPv6.
3. **The broker's whitelist field** must accept an IPv6 literal.
4. **The broker's validation** must compare the address it actually sees against what you registered — which, for an API behind a CDN, means it must read the forwarded client address correctly.

### What I measured (6 Aug 2026)

**DNS — all three brokers publish AAAA records:**

```
api.kite.trade            2606:4700::6810:2232      (Cloudflare)
kite.zerodha.com          2606:4700::6812:7428      (Cloudflare)
a3.aliceblueonline.com    2606:4700::6812:10e3      (Cloudflare)
v2api.aliceblueonline.com 2606:4700::6812:11e3      (Cloudflare)
developer.paytmmoney.com  2600:1417:71:185::3098    (Akamai)
```

**Do not over-read this.** Every one of those is a CDN address, and Cloudflare and Akamai enable IPv6 on the edge by default. The AAAA record proves the *edge* speaks IPv6; it says nothing about the origin, and nothing about whether the broker's IP check sees your real address once the CDN forwards the request. That last point is link 4, and it is the one most likely to break quietly: the origin sees the CDN's IP unless it reads `CF-Connecting-IP` / `X-Forwarded-For`, and whether the whitelist check reads the forwarded value is not documented by any of the three.

**Egress — this machine has no IPv6 at all:**

```
curl -4 https://api.ipify.org   →  117.202.62.60
curl -6 https://api64.ipify.org →  (no response, exit 6)
```

Every `curl -6` to a broker endpoint failed with no connection. That is **not evidence about the brokers** — it is link 1 failing locally. The development machine's ISP path is IPv4-only, so an IPv6 experiment cannot even be run from here. It would have to be run from the OCI VM, which can be given IPv6 free of charge.

**Conclusion: the IPv6 story is unverifiable end to end from here and untested against any broker's order path.** For something whose failure mode is a rejected order, that is not a foundation to build on. IPv4 is the boring, working answer, and it costs ₹0 on the current provider.

---

## Cost landscape

### What a public IPv4 costs per month

| Provider | Public IPv4 | IPv6 | Notes |
|---|---|---|---|
| **OCI (current)** | **Free** — ephemeral and reserved alike; always-free VM includes one | **Free** | Reserved public IPs are not billed, attached or not |
| **AWS** | **$0.005/hr ≈ $3.60/mo** per address, attached *or not*, since 1 Feb 2024 | Free | ~$43.80/yr per IP; applies to EC2, NAT GW, ALB, VPN |
| **Hetzner** | **€0.50/mo** per primary IPv4 | Free | All plan prices quoted "excl. IPv4" |
| **Vultr** | Included in the $3.50+ plans; the $2.50 sandbox plan is **IPv6-only** | Free | IPv6-only tier is limited to 2 instances and limited regions |
| **DigitalOcean** | Included while attached; billed when reserved and idle | Free | — |

The pattern is uniform: **IPv4 is the scarce, billed resource; IPv6 is free.** That is the entire economic argument for IPv6, and at this project's scale it is worth between ₹0 and ~₹300/month — which is less than the cost of one debugging session on a protocol mismatch.

### Where the money actually is

At one address, the IPv4-vs-IPv6 decision is worth at most **$3.60/month**, and on OCI it is worth **nothing at all**, because IPv4 there is already free. IPv6 economics only start to matter at fleet scale — dozens of nodes, where €0.50 each compounds. This project has one VM.

**So: the cost comparison the question asks for has a slightly anticlimactic answer.** On the current provider both protocols are free, so choose on reliability, and reliability says IPv4.

---

## Where to buy, cheapest first

The requirement was an address that comes with usable networking and can be **attached to a larger VM later**. That last clause rules out any provider whose IP is welded to one instance.

### 1. Oracle Cloud — ₹0, and already in use ✅

- **Reserved public IPv4 is free**, and unlike an ephemeral IP it **can be unassigned and reassigned to a different private IP anywhere in the same region** — a different VCN or availability domain included. That is precisely "keep the IP, grow the VM."
- **IPv6 is free too**: Oracle allocates a /56 GUA prefix per VCN, globally routable, supported in all commercial regions, no charge documented.
- Always-free compute: 2× `VM.Standard.E2.1.Micro` (1/8 OCPU, 1 GB, one public IPv4 each), or Ampere A1 at 1,500 OCPU-hours + 9,000 GB-hours/month — about 2 OCPU and 12 GB run continuously.
- Limits worth knowing: 50 reserved public IPs per region, 65 per VNIC.

**Nothing beats free, and the reserved IP already satisfies the resize requirement.** The one caveat is the whole reason the roadmap has a Postgres-on-the-same-VM constraint: always-free capacity is not guaranteed, and Ampere shapes are frequently out of stock in busy regions. Since the IP is reserved and movable, that risk hits the VM, not the address.

### 2. Vultr Mumbai — ~$3.50–5/mo (₹300–450)

The realistic alternative *if Indian latency ever matters*. Mumbai and Delhi regions, single-digit-millisecond RTT to NSE-adjacent endpoints, reserved IPs that detach and reattach. The $2.50 tier is IPv6-only and therefore useless for broker whitelisting unless every broker involved accepts IPv6 — which, per the table above, is not established for two of the three.

Latency is irrelevant to MoneyPlant as it stands. Read-only aggregation on a 30-second refetch does not care about 150 ms.

### 3. Hetzner — €0.50/mo for IPv4, but reconsider

Historically the cheapest credible VPS, and no longer obviously so: the **15 June 2026 repricing raised cloud plans by roughly 30% (ARM/Intel shared) to 175% (CPX/CCX)** — CPX22 went €7.99 → €19.49, CAX11 €4.49 → €5.99. Combined with German-only/US locations (no India), it is now hard to justify over Vultr Mumbai for this workload.

### 4. Dedicated "static IP for algo trading" services — ₹100–300/mo

`staticip.in`, `algoip.in` and similar sell a static IP as a product, aimed exactly at this SEBI mandate. Worth knowing they exist, and worth being sceptical of: you are buying a tunnel endpoint whose reliability you cannot audit, for a compliance-critical path, when OCI gives you a reserved IP for free. Their genuine use case is someone on CGNAT home broadband with no cloud VM — not this project.

**One thing they get right, and it generalises:** shared or rotating proxy pools do not qualify. The address must be traceable to you specifically, and NSE A.7 means it must map to exactly one client.

---

## The constraint that outranks all of the above

While researching broker IPv6 support I found direct confirmation of the "one IP, one client" rule from `REGULATORY-API-STATIC-IP.md`. Zerodha's developer console returns:

> The IP address(es) you are trying to add are already linked to another account. Each IP address can only be linked to one account.

Zerodha's staff confirm the restriction on their forum. So NSE implementation standard A.7 is not a policy someone might overlook — **it is enforced at the point of registration**, before any order is ever sent.

For MoneyPlant this settles a question the cost analysis cannot touch: **buying a better or cheaper IP does not enable multi-user order placement.** One IP serves one client. Two unrelated users placing orders need two addresses and two separate egress paths, which means per-user outbound proxying — and that is before the algo-provider empanelment problem in the companion doc, which is the harder wall anyway.

If order placement is ever added, the cheapest compliant shape is the one the regulation carves out on purpose: **self and family, one static IP, under 10 OPS.** The current OCI reserved IPv4, at ₹0, already is that shape.

## Open items

1. **Test IPv6 from the OCI VM, not from here.** Assign the free IPv6 prefix and retry `curl -6` against `api.kite.trade` and `a3.aliceblueonline.com`. Ten minutes, and it converts links 1–2 from unknown to known.
2. **Check whether Alice Blue's and Paytm's whitelist fields accept an IPv6 literal.** Both consoles are already accessible; this is a look, not a project.
3. **Confirm what the OCI VM actually egresses as today.** `curl -4 https://api.ipify.org` and `curl -6 https://api64.ipify.org` from the VM. If it is dual-stack, that is the Zerodha mismatch trap waiting to happen the day orders are added.
4. **Do not migrate providers on cost grounds.** The current bill for addressing is zero and the reserved IP already survives a VM resize. Revisit only if Indian latency becomes a requirement, which it is not while the app is read-only.
