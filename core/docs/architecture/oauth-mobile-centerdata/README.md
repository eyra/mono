# Eyra ↔ Centerdata integration — design briefing

**Status:** Draft v0.1 — for review with Centerdata (Arnoud Wijnant)
**Author:** Eyra (Melle Lieuwes)
**Date:** 2026-06-10
**Related:** Flux issue [#9972520910](https://app.basecamp.com/5734045/buckets/35926565/todos/9972520910) · Epic [Sense: Mobile App Foundation](https://app.basecamp.com/5734045/buckets/35926565/todos/9972206969)

---

## 1. Purpose

This document proposes the technical integration between **Eyra's Next platform** and **Centerdata** to enable LISS panelists to participate in research assignments through Next — on the web *and* through the Next mobile app.

The goal of this briefing is to align on the integration shape so that Eyra and Centerdata can identify implementation work and next steps.

We make concrete design choices throughout. Each significant choice is followed by a short **Alternatives considered** note explaining what we rejected and why. Genuinely open items are collected in [Section 7 — Open questions for Centerdata](#7-open-questions-for-centerdata).

## 2. Scope

In scope:

- A participant logs in to Next as a LISS panelist (web and mobile).
- Centerdata pre-registers LISS panelists and assignments in Next before the participant has ever signed in.
- Next launches a Centerdata-hosted **Quest** questionnaire on behalf of a logged-in participant and receives a completion signal in return.

Out of scope (for this briefing):

- Email/password sign-up for non-LISS users (handled entirely by Eyra; mentioned only as context).
- Other Centerdata panels beyond LISS (the design leaves room for them; we focus on LISS).
- Eyra-internal data modelling decisions.

## 3. Eyra-side context

Next is the Eyra research platform. The mobile app is a **hybrid**: a thin native shell (iOS/Android) that hosts a mobile-tuned Phoenix LiveView session. Auth state therefore lives server-side, and the same authentication flows work for both web and mobile clients — there is no separate native auth path.

Next already integrates with external identity providers using the OpenID Connect (OIDC) standard. Today, **SurfConext** is wired in as an OIDC IdP using the `Assent` OIDC strategy. **Google sign-in** uses the same pattern. The implementation lives in `lib/core/surfconext/` and `lib/google_sign_in/`.

**Centerdata fits into this same pattern.** From Eyra's perspective, Centerdata is one OIDC IdP among several, serving LISS panelists specifically. No bespoke mobile or LISS-specific authentication flow is introduced.

## 4. The three Eyra ↔ Centerdata interfaces

From Eyra's perspective, Centerdata is **one external party** that we integrate with through three independent logical interfaces. We do not presume how Centerdata splits these internally — e.g., whether the LISS IdP and the Provisioning endpoints are functions extended onto the existing Quest software, or whether they live in separate services. That is Centerdata's call.

| # | Direction | Purpose | Protocol |
|---|-----------|---------|----------|
| 1 | Centerdata → Eyra | Pre-register participants and assignments | REST/JSON, OAuth 2.0 `client_credentials` |
| 2 | Eyra → Centerdata | Authenticate a LISS panelist at sign-in | OpenID Connect (Authorization Code + PKCE) |
| 3 | Eyra → Centerdata (and back) | Launch a Quest questionnaire and receive completion | Signed launch URL + redirect callback |

Each interface is described in detail below.

---

## 5. Interface 1 — Provisioning API

### 5.1 Purpose

Centerdata pre-creates the LISS panelists and their assignments in Next **before any participant ever signs in**, so that a panelist who signs in for the first time immediately sees their assignments waiting.

### 5.2 Direction and authentication

**Direction:** Centerdata calls a REST API exposed by Eyra/Next. Eyra is the resource server.

**Authentication:** OAuth 2.0 **client_credentials** flow.

- Eyra issues Centerdata a `client_id` + `client_secret` pair (one per environment: staging, production).
- Centerdata obtains an access token from Eyra's token endpoint and presents it as a `Bearer` token on every API call.
- Tokens are short-lived (≤ 1 hour). Centerdata refreshes as needed.

**Alternatives considered:**
- *Long-lived API key*: simpler, but harder to rotate and revoke. Rejected — `client_credentials` is the standard for service-to-service, and we already have to speak OAuth/OIDC for Interface 2.
- *Mutual TLS*: stronger transport-level auth, but operationally heavier and not needed for the threat model.

### 5.3 User identifier — the join key

Each user provisioned by Centerdata is identified by **two required fields**:

- `liss_sub` *(required, primary)* — a stable, never-reassigned identifier for the panelist as known to Centerdata's LISS IdP. This is the **primary join key**.
- `email` *(required)* — the panelist's email address. Used for display, notifications, and as a sanity check at first sign-in.

At first sign-in via OIDC, Eyra looks up the pre-registered Next user by matching the OIDC ID token's `sub` claim against the stored `liss_sub`. Email mismatch produces a warning but does **not** block the sign-in — this covers legitimate email changes at Centerdata.

**Rationale:** Email is mutable and occasionally reassigned; relying on email alone for the durable join would break the link when a panelist's email changes at Centerdata. The OIDC `sub` claim is defined by the OIDC spec as locally-unique to the IdP and never-reassigned, making it the canonical join key.

**Alternatives considered:**
- *Email-only matching*: simpler but fragile (see rationale above). Rejected.
- *`sub`-only matching*: cleaner but loses email as a sanity check and a human-meaningful display field at provisioning time. Rejected.

### 5.4 API surface (initial sketch)

The exact API contract is part of the implementation work and will be specified separately. As a starting sketch:

```
POST   /api/centerdata/v1/users               Pre-register a LISS panelist
PATCH  /api/centerdata/v1/users/{liss_sub}    Update a pre-registered user
DELETE /api/centerdata/v1/users/{liss_sub}    Deactivate a user
POST   /api/centerdata/v1/assignments         Create an assignment for one or more users
PATCH  /api/centerdata/v1/assignments/{id}    Update an assignment
DELETE /api/centerdata/v1/assignments/{id}    Withdraw an assignment
```

All requests/responses are JSON. All endpoints return standard HTTP status codes and a structured error body on failure.

## 6. Interface 2 — LISS-OIDC sign-in

### 6.1 Purpose

Authenticate a LISS panelist visiting Next (on web or in the mobile app), using Centerdata's OIDC IdP. After successful sign-in, Eyra has a Phoenix session for the participant, linked to the pre-registered Next user.

### 6.2 Flow

Standard OpenID Connect **Authorization Code with PKCE**. Identical for web and mobile.

1. Participant clicks "Log in with LISS panel" inside a Next page (web browser or mobile WebView).
2. Next (the OIDC Relying Party) constructs an authorization request and redirects the participant to Centerdata's `/authorize` endpoint.
3. On mobile, the redirect opens in an **in-app browser tab** — `ASWebAuthenticationSession` on iOS, **Custom Tabs** on Android. On web, the redirect happens in the same browser tab.
4. The participant authenticates at Centerdata.
5. Centerdata redirects back to Eyra's callback URL with an authorization code.
6. Eyra exchanges the code for tokens at Centerdata's `/token` endpoint and validates the ID token signature against Centerdata's JWKS.
7. Eyra looks up the pre-registered Next user by `id_token.sub == stored.liss_sub`, establishes a Phoenix session, and redirects back to the LiveView (web: same tab; mobile: a universal link / app link that returns the participant to the mobile shell).

### 6.3 What Eyra needs from Centerdata

- OIDC discovery endpoint (`/.well-known/openid-configuration`) — so Eyra can auto-configure the endpoints, supported algorithms, and JWKS URI.
- A registered OIDC client for Eyra (`client_id`, `client_secret`), one per environment (staging, production).
- A list of permitted **redirect URIs** that Centerdata will accept. Eyra will provide them:
  - Web: `https://next.eyra.co/auth/liss/callback` (and equivalent for staging).
  - Mobile: same web URL — mobile shell uses universal links / app links on top of the same URL.

### 6.4 Required ID token claims

| Claim | Required | Notes |
|-------|----------|-------|
| `sub` | yes | Primary join key — must match the `liss_sub` from provisioning. Stable, never reassigned. |
| `email` | yes | Display + sanity check. |
| `email_verified` | recommended | True only if Centerdata has verified ownership. |
| `iss`, `aud`, `iat`, `exp`, `nonce` | yes | Standard OIDC. |

### 6.5 Mobile specifics

The mobile shell does **not** do native OAuth itself. The OIDC flow is driven by Phoenix (server-side); the shell only needs to:

- Open OIDC redirects in a system-provided in-app browser tab (not a WebView) so password managers and Centerdata's existing browser sessions work normally.
- Register universal links / app links so the OIDC callback URL returns control to the mobile shell after Centerdata redirects back.

**Alternative considered: native PKCE direct to Centerdata.** In this variant, the mobile shell would be the OAuth client and obtain tokens directly from Centerdata, then exchange them for a Next session. Rejected because: (a) the Next mobile app is a hybrid LiveView app — auth state lives server-side regardless, so there is little benefit to terminating PKCE in the shell; (b) it would create asymmetric auth paths between web and mobile; (c) it would require Centerdata to maintain a separate mobile client registration with platform-specific concerns (app attestation, store-bound credentials).

## 7. Interface 3 — Quest launch

### 7.1 Purpose

When a logged-in LISS participant taps "Start" on an assignment that is a Quest questionnaire, Next hands off to Centerdata's Quest, the participant completes the questionnaire, and control returns to Next with a completion signal.

### 7.2 Pre-condition

The participant is **already authenticated in Next** as a LISS panelist (Interface 2 has run). Quest launch is therefore not an authentication step — it is an *identity assertion + launch context* handoff. Quest does not need to re-authenticate the user.

### 7.3 Proposed mechanism — signed launch URL

Eyra mints a short-lived signed URL pointing at the Quest questionnaire. The URL carries a JWT (or equivalent signed payload) with the following claims:

| Claim | Purpose |
|-------|---------|
| `iss` | Eyra issuer identifier |
| `aud` | Quest audience identifier |
| `liss_sub` | Identifies the participant in LISS terms |
| `questionnaire_id` | Which questionnaire to load |
| `assignment_id` | Eyra's assignment identifier (echoed back at completion) |
| `nonce` | One-time, prevents replay |
| `iat`, `exp` | Issued at, short expiry (~ 60 seconds) |
| `return_url` | Where Quest should send the participant after completion |

Quest validates the signature against Eyra's published public key (`/.well-known/jwks.json` on Eyra's side), checks `aud`, `exp`, and `nonce`, then opens the questionnaire. On completion, Quest redirects the participant to `return_url`, with a signed completion payload (or a callback `POST` to a Next webhook — see open questions).

This is the **LTI-style** pattern used widely in ed-tech for launching external assessments on behalf of an authenticated user.

**Alternatives considered:**
- *Quest re-runs its own OIDC against Centerdata*: would re-authenticate a user who is already authenticated upstream. Wasteful and adds a fragile re-auth step (cookies don't reliably cross WebView boundaries on mobile). Rejected.
- *Pass through the Centerdata access token from Interface 2*: only useful if Quest needs to make authenticated calls back to Centerdata APIs as the user. Out of scope for the questionnaire-launch use case. Rejected for now; can be revisited.
- *Session-based / shared cookies between Quest and the Centerdata IdP*: relies on browser cookie context that does not survive WebView / app-link transitions on mobile. Rejected.

### 7.4 Completion signal

Two patterns are common; either or both can be supported:

- **Redirect with signed payload**: Quest redirects to `return_url` with a signed query parameter containing completion status (`completed`, `partial`, `abandoned`).
- **Server-to-server webhook**: Quest `POST`s to a Next webhook with the signed completion payload, independent of the redirect. More reliable if the participant abandons the redirect.

Eyra's preference is to support **both**: the redirect for immediate UX continuity, and the webhook for guaranteed completion bookkeeping.

## 8. Open questions for Centerdata

These are the items where Eyra has made a working assumption but Centerdata's answer determines the implementation:

1. **OIDC support and conformance.** Can Centerdata's LISS IdP serve as an OIDC IdP supporting Authorization Code + PKCE, with discovery (`/.well-known/openid-configuration`) and a JWKS endpoint?
2. **`sub` stability.** Can Centerdata guarantee the OIDC `sub` claim is stable and never reassigned for the lifetime of a LISS panelist?
3. **Email claim.** Will Centerdata include `email` (and ideally `email_verified`) in the ID token?
4. **Provisioning API direction.** We propose Centerdata calls an Eyra-exposed REST API authenticated with `client_credentials`. Does this fit Centerdata's operational model, or does Centerdata prefer Eyra to poll Centerdata endpoints?
5. **Quest launch mechanism.** What signed-launch mechanism does Quest already support — LTI 1.3, a bespoke JWT scheme, shared HMAC, or something else? We propose to align with whatever Quest already does rather than introduce a new contract.
6. **Quest completion callback.** Does Quest support a server-to-server completion webhook in addition to the redirect, and what signing/auth does it expect?
7. **Account lifecycle signals.** How does Centerdata signal participant deactivation or removal (provisioning `DELETE`, periodic reconciliation, lifecycle webhook)?
8. **Per-pool client identities.** If Centerdata supports multiple panels (LISS primary, secondary, etc.) in the future, does each panel get its own OIDC client_id, or is one shared client identity with `scope`/claims used to distinguish them?

## 9. Diagrams

Four diagrams accompany this document, all generated from `workspace.dsl` (Structurizr DSL). Centerdata is modelled as a single external Software System throughout — its internal split is not assumed. Steps in the dynamic views are tagged with `[Provisioning]`, `[LISS IdP]`, or `[Quest]` to identify which interface they belong to. See [`diagrams.md`](diagrams.md) for regeneration instructions.

- **Context** (`structurizr-Context.png`) — Participant, Eyra/Next, Centerdata, and the operators on each side.
- **Interface 1 — Provisioning** (`structurizr-Provisioning.png`) — Dynamic view: Centerdata pre-registers a participant and an assignment, authenticated via `client_credentials`.
- **Interface 2 — LISS-OIDC sign-in** (`structurizr-SignIn.png`) — Dynamic view: OIDC Authorization Code + PKCE flow, identical for web and mobile.
- **Interface 3 — Quest launch** (`structurizr-QuestLaunch.png`) — Dynamic view: signed JWT launch URL, questionnaire completion, redirect + webhook return.

## 10. Glossary

- **Next** — Eyra's research platform (Phoenix / LiveView).
- **LISS** — The Longitudinal Internet studies for the Social Sciences panel, operated by Centerdata.
- **Quest** — Centerdata's questionnaire system that hosts the actual web questionnaires.
- **OIDC** — OpenID Connect, the identity layer on top of OAuth 2.0.
- **PKCE** — Proof Key for Code Exchange (RFC 7636), an OAuth 2.0 extension that protects the authorization code from interception.
- **RP** — Relying Party, the OIDC term for the OAuth client that consumes identity assertions from an IdP.
- **IdP** — Identity Provider.
- **`sub`** — The OIDC subject identifier claim — a stable, never-reassigned identifier for the user as known to the IdP.
- **LiveView** — Phoenix's server-driven UI framework; the Next mobile shell hosts a LiveView session.
- **LTI** — Learning Tools Interoperability, an ed-tech standard for launching external tools with a signed identity assertion.
