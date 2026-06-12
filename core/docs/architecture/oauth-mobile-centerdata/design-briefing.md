# Next ↔ Centerdata integration — design briefing

**Status:** Draft v0.1 — for review with Centerdata (Arnoud Wijnant)
**Author:** Eyra (Melle Lieuwes)
**Date:** 2026-06-10
**Related:** Flux issue [#9972520910](https://app.basecamp.com/5734045/buckets/35926565/todos/9972520910) · Epic [Sense: Mobile App Foundation](https://app.basecamp.com/5734045/buckets/35926565/todos/9972206969)

---

## What Centerdata needs to build

To let LISS panelists participate in Next assignments via web and the Next mobile app, Centerdata implements three things — all using standard OAuth 2.0 / OIDC mechanics, no Next-specific protocol:

- **An OIDC Identity Provider.** Expose `/.well-known/openid-configuration` and a JWKS endpoint. Support the **Authorization Code + PKCE** flow. Register Next as a client (one `client_id` + `client_secret` per environment) and accept Next's `redirect_uri`. Include `sub` (stable, never reassigned), `email`, and ideally `email_verified` in the ID token.
- **A CSV export from the LISS panel.** Centerdata's operator enrolls participants on an assignment by uploading a CSV via Next's CMS. The CSV needs `centerdata_sub` and `email` (plus an optional `label` for human audit). See §5 for the contract.
- **A signed-JWT launch handler for questionnaires.** Accept a signed launch URL from Next, verify the signature against Next's published JWKS (`/.well-known/jwks.json`), open the questionnaire, and return the participant to `return_url` with a signed completion payload (and ideally POST a completion webhook).

The three interfaces are independent — Centerdata is free to host them in the same service or in separate ones; this design makes no assumption either way.

Please also review the [open questions in §7](#7-open-questions-for-centerdata) — your answers determine the final shape of the contract.

---

## Setup sequence

**One time:**

1. Centerdata stands up an OIDC IdP (publish discovery + JWKS, register Next as a client, accept Next's `redirect_uri`). See §6.3.
2. The Centerdata operator gets a Next user account with the creator role.

**Per assignment:**

3. The operator creates (or selects) a project and creates an assignment in it via the Next CMS.
4. The operator adds a **Quest task** to the assignment workflow and populates its URL field with the Centerdata-hosted questionnaire URL. See §7.2.
5. The operator imports a CSV (exported from the LISS panel) on the assignment. See §5.
6. Eyra verifies and **publishes** the assignment, making it available to participants.

After publishing, runtime flows (§6 sign-in and §7 launch) work as described.

---

## 1. Purpose

This document proposes the technical integration between **Next** and **Centerdata** to enable LISS panelists to participate in research assignments through Next — on the web *and* through the Next mobile app.

The goal of this briefing is to align on the integration shape so that Eyra and Centerdata can identify implementation work and next steps.

We make concrete design choices throughout. Genuinely open items are collected in [Section 7 — Open questions for Centerdata](#7-open-questions-for-centerdata).

## 2. Scope

In scope:

- A participant logs in to Next as a LISS panelist (web and mobile).
- Centerdata enrolls LISS panelists on an assignment in Next (via CSV upload), at any time.
- Next launches a Centerdata-hosted questionnaire on behalf of a logged-in participant and receives a completion signal in return.

Out of scope (for this briefing):

- Eyra-internal data modelling decisions.

## 3. Next overview

Next is Eyra's research platform. The mobile app is a **hybrid**: a thin native shell (iOS/Android) that hosts a mobile-tuned Phoenix LiveView session. Auth state therefore lives server-side, and the same authentication flows work for both web and mobile clients — there is no separate native auth path.

Next already integrates with external identity providers using the **OpenID Connect (OIDC)** standard — the identity layer built on top of OAuth 2.0. An OIDC IdP authenticates the user and returns a signed **ID token** containing identity claims. SURFconext (academic SSO) and Google sign-in are wired in today; **Centerdata fits the same pattern**, with no bespoke mobile or LISS-specific flow introduced.

In other words, what Centerdata implements is a standard OIDC IdP. Nothing about the contract is Next-specific.

## 4. The three Next ↔ Centerdata interfaces

From Eyra's perspective, Centerdata is **one external party** that we integrate with through three independent logical interfaces. We do not presume how Centerdata splits these internally — whether the OIDC and questionnaire endpoints are functions of the same system or live in separate services. That is Centerdata's call. (Interface 1 — participant enrollment — runs entirely through the Next CMS via CSV upload and requires no endpoint on Centerdata's side.)

| # | Direction | Purpose | Protocol |
|---|-----------|---------|----------|
| 1 | Centerdata → Next | Enroll participants on an assignment | CSV upload via the Next CMS |
| 2 | Next → Centerdata | Authenticate a LISS panelist at sign-in | OpenID Connect (Authorization Code + PKCE) |
| 3 | Next → Centerdata (and back) | Launch a questionnaire and receive completion | Signed launch URL + redirect callback |

Each interface is described in detail below.

---

## 5. Interface 1 — CSV import

### 5.1 Purpose

Centerdata enrolls LISS panelists on an assignment in Next, so that when they sign in (or on their next session if already signed in) they see and can start the assignment.

### 5.2 Shape

- Centerdata exports a CSV from the LISS panel.
- A Centerdata operator — a regular Next user with the **creator role** on the relevant project — uploads the CSV via the Next CMS's "Import participants" button on the assignment.
- The CSV is the **declarative truth** for that assignment's participant list: importing replaces the list, except for participants who have already started the assignment (they are protected and kept).

### 5.3 CSV contract

| Column | Required | Purpose |
|---|---|---|
| `centerdata_sub` | yes | The value of the OIDC `sub` claim Centerdata will issue for this panelist at sign-in. Primary join key — stable, never reassigned. |
| `email` | yes | Display, notifications, and sanity check at first sign-in. |
| `label` | no | Free-form human-readable handle (a name, a Centerdata-internal panel ID, a batch tag). Helps operators recognize rows. Per-assignment, not per-user. |

File format is standard RFC 4180 CSV, UTF-8, with the header row above (column order does not matter).

### 5.4 Authority over user-level fields

Both CSV import and OIDC sign-in can **create** a User record if none exists yet for a given `centerdata_sub`. Only OIDC sign-in can **update** an existing User record (`email` is overwritten with whatever the live ID token issues). CSV import never overwrites User fields — it only writes Participant rows (user ↔ assignment membership, plus per-assignment `label`).

This way a stale CSV cannot roll back a fresher email that Centerdata's IdP issued at sign-in.

### 5.5 Rationale

- **`sub` as primary join key.** The OIDC `sub` claim is spec-defined as locally-unique to the IdP and never reassigned. Email alone would break the link when a panelist's email changes at Centerdata. *Rejected:* email-only matching (fragile); `sub`-only with no email (loses display + sanity check).
- **Declarative replace with protected-started carve-out.** Operators can re-sync any time by re-exporting; in-flight participants are never silently removed.


## 6. Interface 2 — OIDC sign-in

### 6.1 Purpose

Authenticate a LISS panelist visiting Next, using Centerdata's OIDC IdP. After successful sign-in, Next has a session for the participant. If they have been imported into one or more assignments, those appear on the home page; otherwise the home page shows an empty state.

### 6.2 Flow

Standard OpenID Connect **Authorization Code with PKCE**. Identical for web and mobile.

Two concepts to keep in mind:

- **Authorization Code flow** — the OIDC flow where the IdP, after authenticating the user in the browser, returns a short-lived *authorization code* to the client (Next) via redirect. Next then exchanges that code for tokens by making a server-to-server `POST` to the IdP's token endpoint. The user-agent never sees the tokens.
- **PKCE** (Proof Key for Code Exchange, RFC 7636) — Next generates a one-time secret (`code_verifier`) at the start of the flow and sends only a hash of it (`code_challenge`) with the authorization request. To exchange the code, Next has to present the original verifier. An attacker who intercepts the code alone cannot use it.

Steps:

1. Participant clicks "Log in with LISS panel" inside a Next page.
2. Next (the OIDC **Relying Party** — the client that consumes the IdP's assertions) constructs an authorization request and redirects the participant to Centerdata's `/authorize` endpoint.
3. On mobile, the redirect opens in an embedded web browser; on web, in the same browser tab.
4. The participant authenticates at Centerdata.
5. Centerdata redirects back to Next's callback URL with an authorization code.
6. Next exchanges the code for tokens at Centerdata's `/token` endpoint and validates the ID token signature against Centerdata's **JWKS** (JSON Web Key Set — the set of public keys Centerdata publishes at a discoverable URL, used to verify ID token signatures).
7. Next looks up the user by `id_token.sub == stored.centerdata_sub` (creating a fresh user record if this is a first-time sub), updates the user's email from the ID token, establishes a session, and redirects the participant back into the Next UI.

### 6.3 What Next needs from Centerdata

- OIDC discovery endpoint (`/.well-known/openid-configuration`) — so Next can auto-configure the endpoints, supported algorithms, and JWKS URI.
- A registered OIDC client for Next (`client_id`, `client_secret`), one per environment (staging, production).
- A list of permitted **redirect URIs** that Centerdata will accept. Next's URIs are:
  - Web: `https://next.eyra.co/auth/liss/callback` (and equivalent for staging).
  - Mobile: same web URL — mobile shell uses universal links / app links on top of the same URL.

### 6.4 Required ID token claims

The ID token is a signed JWT (JSON Web Token — a signed, base64url-encoded JSON payload) whose body carries claims about the authenticated user.

| Claim | Required | Notes |
|-------|----------|-------|
| `sub` | yes | Subject — the IdP's stable, never-reassigned identifier for the user. Next's primary join key — matched against the `centerdata_sub` of any CSV-imported participant rows. |
| `email` | yes | Display + sanity check at first sign-in. |
| `email_verified` | recommended | True only if Centerdata has verified ownership. |
| `iss` | yes | Issuer — the IdP's identifier URL. Next checks it matches Centerdata's published issuer. |
| `aud` | yes | Audience — must contain Next's `client_id`, so the token can't be replayed against a different RP. |
| `iat` | yes | Issued-at timestamp. |
| `exp` | yes | Expiry timestamp — Next rejects expired tokens. |
| `nonce` | yes | A random value Next generates per authorization request and includes in the request; Centerdata echoes it back in the ID token. Next checks it matches, which prevents replay of a captured ID token. |

### 6.5 Mobile — same contract as web

From Centerdata's side, the mobile flow is **identical** to the web flow: same OIDC client, same `client_id`, same `redirect_uri`, same `/authorize` and `/token` endpoints. There is no separate mobile client registration to maintain.

Next absorbs the mobile/web difference internally — the OIDC flow stays server-side.

## 7. Interface 3 — Questionnaire launch

### 7.1 Purpose

When a logged-in LISS participant taps "Start" on an assignment that points at a Centerdata-hosted questionnaire, Next hands off to Centerdata, the participant completes the questionnaire, and control returns to Next with a completion signal.

### 7.2 Pre-conditions

**Setup (per assignment, one-time):** The assignment's workflow in the Next CMS contains a **Quest task**, added by the Centerdata operator. The Quest task has a URL field that the operator populates with the URL of the Centerdata-hosted questionnaire to launch.

**Runtime:** The participant is **already authenticated in Next** as a LISS panelist (Interface 2 has run). Questionnaire launch is therefore not an authentication step — it is an *identity assertion + launch context* handoff. Centerdata does not need to re-authenticate the user.

### 7.3 Proposed mechanism — signed launch URL

Next mints a short-lived signed URL pointing at Centerdata's questionnaire endpoint. The URL carries a JWT (signed, base64url-encoded JSON payload — same format as the OIDC ID token) with the following claims. The roles here are reversed from Interface 2: this time Next signs, Centerdata verifies.

| Claim | Purpose |
|-------|---------|
| `iss` | Issuer — Next's identifier URL; Centerdata uses this to fetch Next's public keys. |
| `aud` | Audience — identifies Centerdata as the intended recipient; prevents the token being replayed against a different system. |
| `centerdata_sub` | Identifies the participant using the `sub` Centerdata previously issued at sign-in. |
| `questionnaire_id` | Which questionnaire to load. |
| `assignment_id` | Next's assignment identifier (echoed back at completion). |
| `nonce` | One-time random value that Centerdata records to detect a replayed launch URL. |
| `iat`, `exp` | Issued-at and expiry timestamps. Short expiry (~ 60 seconds) so a leaked URL is useless almost immediately. |
| `return_url` | Where Centerdata should send the participant after completion. |

Centerdata validates the JWT signature against Next's public key (which Next publishes at `/.well-known/jwks.json` — same JWKS mechanism as in Interface 2, just with roles reversed), checks `aud`, `exp`, and `nonce`, then opens the questionnaire. On completion, Centerdata redirects the participant to `return_url`, with a signed completion payload (or a callback `POST` to a Next webhook — see open questions).

This is the **LTI-style** pattern — Learning Tools Interoperability, an ed-tech standard where a Learning Management System hands off to an external tool with a signed identity assertion instead of forcing the user to re-authenticate. Widely used for launching external assessments on behalf of an already-authenticated user.

**Alternatives considered:**
- *Re-authenticate via OIDC at questionnaire launch*: instead of handing over a signed assertion, send the participant through OIDC again at launch time. Wasteful (they just signed in) and adds a fragile re-auth step — cookies don't reliably cross WebView boundaries on mobile. Rejected.
- *Pass through the Centerdata access token from Interface 2*: only useful if the questionnaire needs to call further authenticated Centerdata APIs on behalf of the user. Out of scope for the questionnaire-launch use case. Rejected for now; can be revisited.
- *Session-based / shared cookies*: relies on browser cookie context that does not survive WebView / app-link transitions on mobile. Rejected.

### 7.4 Completion signal

Two patterns are common; either or both can be supported:

- **Redirect with signed payload**: Centerdata redirects to `return_url` with a signed query parameter containing completion status (`completed`, `partial`, `abandoned`).
- **Server-to-server webhook**: Centerdata `POST`s to a Next webhook with the signed completion payload, independent of the redirect. More reliable if the participant abandons the redirect.

Eyra's preference is to support **both**: the redirect for immediate UX continuity, and the webhook for guaranteed completion bookkeeping.

## 8. Open questions for Centerdata

These are the items where Eyra has made a working assumption but Centerdata's answer determines the implementation:

1. **OIDC support and conformance.** Can Centerdata's OIDC endpoint support Authorization Code + PKCE, with discovery (`/.well-known/openid-configuration`) and a JWKS endpoint?
2. **`sub` stability.** Can Centerdata guarantee the OIDC `sub` claim is stable and never reassigned for the lifetime of a LISS panelist?
3. **Email claim.** Will Centerdata include `email` (and ideally `email_verified`) in the ID token?
4. **CSV export from the LISS panel.** Can Centerdata produce a per-assignment export of LISS panelists with at least `centerdata_sub` and `email` (plus optionally a human-recognizable `label`)? And which Centerdata role(s) would operate the import on the Next side?
5. **Questionnaire launch mechanism.** What signed-launch mechanism does Centerdata's questionnaire system already support — LTI 1.3, a bespoke JWT scheme, shared HMAC, or something else? We propose to align with whatever Centerdata already does rather than introduce a new contract.
6. **Questionnaire completion callback.** Does Centerdata support a server-to-server completion webhook in addition to the redirect, and what signing/auth does it expect?
7. **Per-pool client identities.** If Centerdata supports multiple panels (LISS primary, secondary, etc.) in the future, does each panel get its own OIDC client_id, or is one shared client identity with `scope`/claims used to distinguish them?

## 9. Diagrams

Three diagrams accompany this document, all generated from `workspace.dsl` (Structurizr DSL). Centerdata is modelled as a single external Software System throughout — its internal split is not assumed, and the diagrams therefore do not name any internal Centerdata component. See [`diagrams.md`](diagrams.md) for regeneration instructions.

- **Context** (`structurizr-Context.png`) — Participant, Next, Centerdata, and the operators on each side.
- **Interface 2 — OIDC sign-in** (`structurizr-SignIn.png`) — Dynamic view: OIDC Authorization Code + PKCE flow, identical for web and mobile.
- **Interface 3 — Questionnaire launch** (`structurizr-QuestionnaireLaunch.png`) — Dynamic view: signed JWT launch URL, questionnaire completion, redirect + webhook return.

Interface 1 (CSV import) is a manual operator flow, not a runtime interaction — no dynamic diagram.

## 10. References — prerequisite reading

The OAuth/OIDC concepts in this document are explained inline, but spec-level grounding helps when implementing. The following are the authoritative specs.

**Core (recommended before implementing):**

- [OAuth 2.0 — RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749) — the base OAuth framework. Defines grants (including `client_credentials`), tokens, the authorization endpoint, the token endpoint.
- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html) — the identity layer on top of OAuth 2.0. Defines the ID token, the standard claims (`sub`, `iss`, `aud`, `nonce`, …), and the Authorization Code flow used in Interface 2.
- [PKCE — RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636) — Proof Key for Code Exchange; the `code_verifier` / `code_challenge` mechanism that protects the authorization code.

**Reference (look up as needed):**

- [OpenID Connect Discovery 1.0](https://openid.net/specs/openid-connect-discovery-1_0.html) — defines `/.well-known/openid-configuration` and the IdP metadata document.
- [Well-Known URIs — RFC 8615](https://datatracker.ietf.org/doc/html/rfc8615) — the general `/.well-known/` convention.
- [JWT — RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519), [JWS — RFC 7515](https://datatracker.ietf.org/doc/html/rfc7515), [JWK — RFC 7517](https://datatracker.ietf.org/doc/html/rfc7517) — the JSON Web Token format, its signature container, and the key format used in JWKS.
- [OAuth 2.0 Security Best Current Practice — RFC 9700](https://datatracker.ietf.org/doc/html/rfc9700) — modern security guidance for new OAuth implementations.

## 11. Glossary

- **Next** — Eyra's research platform.
- **LISS** — The Longitudinal Internet studies for the Social Sciences panel, operated by Centerdata.
- **OIDC** — OpenID Connect, the identity layer on top of OAuth 2.0.
- **PKCE** — Proof Key for Code Exchange (RFC 7636), an OAuth 2.0 extension that protects the authorization code from interception.
- **RP** — Relying Party, the OIDC term for the OAuth client that consumes identity assertions from an IdP.
- **IdP** — Identity Provider.
- **`sub`** — The OIDC subject identifier claim — a stable, never-reassigned identifier for the user as known to the IdP.
- **LTI** — Learning Tools Interoperability, an ed-tech standard for launching external tools with a signed identity assertion.
