# One dropdown adds any registration

**Type:** decision · **Date:** 30 Sep 2026 · **Scope:** `frontend` `/app/settings`

## The decision

Adding a broker registration is **one inline panel with the broker as a `Select`
field inside it**, not a menu that picks a broker and then spawns a form. Both
former add paths are deleted: the header `DropdownMenu`, and the per-broker
"Add another registration" button.

## Why

The page rendered **broker, registration and account at identical visual
weight** — a stack of same-sized cards — so nothing in the layout said a
registration belongs *to* a broker and an account *to* a registration. That is
what made a short page read as a wall of boxes, and it is the reason the owner
called it unpleasant. The fix is hierarchy: group header → row → badge.

The two add paths were the same act wearing different clothes. Adding a first
registration at Paytm and a second at Kite differ only in whether a name is
needed. Once the broker is a *field*, that difference is one conditional input,
and the button that was permanently parked on every broker group — for
something the code's own comment said most users never need — can go.

**That button was also the most misread control on the page.** It looks like how
you add a second trading *account*, which is the Connect button three lines
above it. Deleting it removes the confusion rather than re-wording it.

Inline rather than a modal: the one case needing surrounding context is naming a
second registration, and that is exactly when the names already in use should
stay on screen. It also meant adding one primitive instead of two.

## What was rejected

- **A broker rail with a detail pane** (the two-pane option). Better at roughly
  six or more brokers — the user-configured-brokers backlog — but with three it
  spends a column to hide two-thirds of a page that already fits on one screen,
  and makes "is everything connected?" a three-click answer. Parked, not
  rejected: the row and the panel are the same components either way, only the
  container changes.
- **Listing supported-but-unconfigured brokers** as dimmed rows with a Set up
  action. Drafted, then **cut by the owner**: a row for a broker you have not
  set up is clutter on a page you open to manage the ones you have. The full
  list lives in the Add dropdown, which is where you go when you want it.
- **A native `<select>`.** Zero dependencies and perfect mobile behaviour, but
  `<option>` cannot hold a broker mark or a registration count.

## What it cost, and what it caught

`@radix-ui/react-select` is a new dependency. `dropdown-menu` was already there
but is a *command* menu; a broker is a *form value*, and only a listbox reports
its selection to assistive technology and types ahead on option text.

Three defects surfaced while doing it, none of them on `P0-LAUNCH.md`:

1. **A dead session read as healthy.** `connection.connected` was never read, so
   an expired token printed "Linked ZG1234" — while `Topbar`, which does read
   it, printed "Partial" for the same account on the same screen. Two surfaces,
   opposite answers. See [[an-unmeasured-zero-is-a-claim]] for the same shape of
   bug: a field that exists to say "this is not what it looks like", ignored by
   a consumer that then renders the reassuring reading.
2. **`fieldByKey` threw.** `BrokerDefinition.credentialFields` is a list
   precisely so a broker can need something other than a key and a secret, and
   `BrokerAuthType` already admits `ACCESS_TOKEN` — but the form looked up
   exactly `"apiKey"` and `"apiSecret"` and threw when either was absent,
   crashing the card on render. The catalogue from PR #22 was defeated at its
   last mile. Iterating cannot fail that way.
3. **A global `addDisabled`** dimmed every add button on the page when any one
   form opened, with no explanation rendered. Disabled-with-no-reason reads as
   broken, not busy.

## Two things the browser caught that review did not

Both inside the new `ui/select.tsx`, both invisible in the diff:

- Radix's `ItemText` renders a **plain inline span**, so a flex row on
  `SelectItem` does not reach the children inside it — the broker's icon tile
  wrapped onto its own line above the label. Flexing `ItemText` via `asChild`
  is the fix.
- Radix clones **only `ItemText`** into the trigger. Per-option metadata (a
  registration count) placed inside it comes back as part of the selected
  value, so it has to sit outside — hence the `meta` prop.

This is the third time a rendered page caught something code review could not,
after the strategy builder's always-"N/A" risk:reward and its `--₹8,250.00`.
Treat "it typechecks" as necessary and not sufficient for anything with a
layout.

## Related

[[credentials-per-user-per-registration]] — why a registration is not an
account, which is the distinction this layout finally makes visible.
[[dev-auth-bypasses-google-locally]] — how the page was exercised against real
stored credentials without a Google sign-in.
