---
name: overview-shows-what-needs-attention
description: The Overview answers "what should I do?" — one accounts table plus a Needs attention band replaced the duplicated broker tables and the positions/holdings previews (7 Oct 2026).
metadata:
  type: project
---

On 7 Oct 2026 the owner chose concept A of three Overview mockups: the summary strip, **one**
accounts table (P&L and capital together), and a **Needs attention** band. It replaced two tables
that listed every account twice and two previews that were smaller copies of the Positions and
Holdings pages. Tracked in `OVERVIEW-REDESIGN.md`; logic in `frontend/src/features/dashboard/attention.ts`.

**Why:** the Overview is opened to ask "is anything wrong, and do I need to act?", and the old page
answered neither. It also did not fit a laptop screen once four brokers were connected.

**Rules, confirmed by the owner:**
- Margin pressure from **75%** used, **per account**. The strip names the *tightest* account beside the
  combined figure, because capital is held per account: 27% overall hid a Kite account at 84%.
  Utilisation bars turn amber at the same 75%, so amber means one thing everywhere.
- Expiring soon: open legs within **7 IST calendar days** (fixed +05:30, no tzdata), grouped by account
  and expiry, plus the next expiry after the window.
- Biggest moves: top **3** legs by |Day P&L|, at least **₹100**, priced legs only. They are information,
  not a problem, so they do **not** stop a day being "all clear".
- To fix: unconnected broker (Connect), expired session (Reconnect), failed call (never "reconnect"),
  unpriced legs, non-LIVE risk estimates. `UNSUPPORTED_CAPABILITY` is not a fix item.
- The Overview no longer shows the per-account warning banners: the To fix card carries them.

**How to apply:** change a threshold in `attention.ts` and nowhere else; keep the moves card out of the
all-clear decision; keep "tightest account" whenever capital is shown combined. Related:
[[ux-mockup-redesign]], [[premium-left-is-negated-market-value]].
