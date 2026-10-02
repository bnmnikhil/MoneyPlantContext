# Broker API terms for a multi-user, open sign-up MoneyPlant

**Researched 2 Oct 2026**, for the public-launch plan (`PUBLIC-LAUNCH.md`, item L1).
Regulatory and contractual reference, **not legal advice**. Quotes are from the broker's
own terms page or PDF; anything from a forum is labelled as such.

## The question

MoneyPlant's model (ADR / `memory/credentials-per-user-per-registration.md`): every user
registers **their own** developer app at each broker, pastes its API key and secret into
MoneyPlant, and MoneyPlant's server holds the encrypted secret, performs the login
handshake, and holds the resulting access token to read that user's positions, holdings
and margins. Read-only; no orders.

Inviting a few known people made this a grey area. **Opening sign-up to anyone moves it
from grey to the thing the terms address directly.**

## Zerodha — Kite Connect ([kite.trade/terms](https://kite.trade/terms/))

- **§2, API usage:** the APIs may be used "for personal use, where You, a Client, develops
  a private interface exclusively for customising personal trading and investment
  experience, **or this may be for building a trading platform**."
- **§4(a), prohibitions:** may not "Sublicense the APIs for use by a third party."
- **§4(b), confidentiality:** "Your credentials (such as passwords, API keys and secrets,
  and Client IDs) are intended to be used only by you. You will keep your credentials
  confidential and make reasonable efforts to prevent and discourage other API Clients
  from using your credentials."
- **§4(b), content:** may not "Scrape, build databases, or otherwise create permanent
  copies of such content, or keep cached copies with the intent of redistributing", and
  live market data "cannot be displayed to the public at large".
- **Forum, Zerodha staff (not the terms):** "Kite Connect is provided for personal use
  only. You will need to speak to compliance for multi-user access with the project
  description." ([discussion 9947](https://kite.trade/forum/discussion/9947/how-to-share-the-app))
  Staff in the same thread also mention per-user pricing unless the app targets mass users.
  The API-secret FAQ thread says never to share the secret with a third party
  ([discussion 7796](https://kite.trade/forum/discussion/7796/is-it-safe-to-share-my-api-secret-key-to-third-party)).

**Reading.** The user owning their own app avoids *sublicensing* MoneyPlant's app, which
is why 3d was designed that way. It does **not** clearly answer §4(b): a user who pastes
their secret into MoneyPlant is letting a third party use their credentials. And
`raw_capture` / the snapshot tables are "permanent copies" of API content, but not
redistributed: each user sees only their own data. Zerodha's own staff name the route:
**ask compliance, with a project description.**

## Alice Blue — ANT API terms ([PDF](https://alicebluewebsite.s3.ap-south-1.amazonaws.com/wp-content/uploads/2022/12/16044803/TC_API_Usage-1629294490195.pdf))

The text is close to a copy of Kite's, with one useful difference:

- **§2:** personal use, "or this may be for building a trading platform which in turn
  will be offered to the public, other Clients of Alice Blue … You are responsible for
  ensuring You adhere to these platform guidelines and regulations, and seeking
  appropriate regulatory approvals if necessary."
- **§4(a)(1):** may not "Sublicense the APIs for use by a third party."
- **§4(b):** confidentiality of credentials. The PDF's text layer is corrupted at this
  clause, so it has not been quoted. The search summary renders it as "API credentials will
  not be disclosed to any third party without Alice Blue's prior written consent".
  **Re-read the PDF visually before relying on that wording.**
- Alice Blue's vendor docs ([Vendors](https://ant.aliceblueonline.com/productdocumentation/Vendors/))
  describe a separate **vendor** route, where the admin team reviews and activates an app
  that offers the API to other users. This is the platform-shaped path, and the same admin
  activation that already produces `"Invalid vendor id"` for unactivated user apps.

## Paytm Money — Open API ([developer.paytmmoney.com](https://developer.paytmmoney.com/))

No published terms of use were found. The marketing copy explicitly invites third-party
developers: traders may "hire a third party developer to code the trading tool", and
fintech startups may build "a full fledged innovative trading and investment platform"
free of cost. Contact: `openapi.care@paytmmoney.com`. **Unanswered, not permissive.**

## What this means for launch

1. **Ask all three in writing before opening sign-up** (L1). Short, factual project
   description: read-only, no orders, each user's own app, secret encrypted with
   AES-256-GCM under a key outside the database, each user sees only their own data, no
   market data shown to anyone but the account holder.
2. Zerodha is the one that matters most. Kite is the broker most users will connect, and
   it is the only one whose staff have said "personal use only" in so many words.
3. **If Zerodha refuses or does not answer by go/no-go,** the options are, in order of
   preference: (a) keep sign-up allowlisted (the P0 invite beta) until it answers;
   (b) open sign-up with Kite marked "owner's own account only" (connect disabled for
   other users); (c) launch anyway. (c) risks a revoked API app **for the user, not for
   MoneyPlant**, and it puts that risk on users who cannot see it.
4. A design mitigation, if compliance objects specifically to the server holding the
   secret: Kite's token exchange needs only `sha256(api_key + request_token + api_secret)`.
   That checksum can be computed **in the user's browser**, so the secret never reaches the
   server. The cost: the secret lives in browser storage, or is re-typed every day. Keep
   this in reserve; do not build it speculatively.

## Related, not re-researched here

- SEBI static-IP / algo rules bind order placement only → `REGULATORY-API-STATIC-IP.md`.
- **SEBI Research Analyst exposure.** The RA Regulations reach anyone publishing
  "research" or recommendations on securities, including algorithmic tools (SEBI RA FAQs,
  circular SEBI/HO/MIRSD/MIRSD-PoD/P/CIR/2025/105, 23 Jul 2025). The comparable Indian
  options platforms, Sensibull and the LTP Calculator, are **themselves registered RAs**.
  That proves nothing about MoneyPlant, but it is a signal. A payoff calculator over legs
  the user chose is the defensible end. A screener that **ranks specific trades** is the
  exposed end, which is why it stays hidden at launch.
- **DPDP Rules 2025** were notified Nov 2025. Data Fiduciary obligations (notice, consent,
  safeguards, breach reporting, erasure) become enforceable **13 May 2027**. So they are
  not legally due at launch, but they are cheap, and a broker's compliance team will ask
  about them.
