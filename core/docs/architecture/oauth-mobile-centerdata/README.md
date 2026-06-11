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
- Next launches a Centerdata-hosted questionnaire on behalf of a logged-in participant and receives a completion signal in return.

Out of scope (for this briefing):

- Email/password sign-up for non-LISS users (handled entirely by Eyra; mentioned only as context).
- Other Centerdata panels beyond LISS (the design leaves room for them; we focus on LISS).
- Eyra-internal data modelling decisions.

## 3. Eyra-side context

Next is the Eyra research platform. The mobile app is a **hybrid**: a thin native shell (iOS/Android) that hosts a mobile-tuned Phoenix LiveView session. Auth state therefore lives server-side, and the same authentication flows work for both web and mobile clients — there is no separate native auth path.

Next already integrates with external identity providers using the **OpenID Connect (OIDC)** standard — the identity layer built on top of OAuth 2.0. An OIDC IdP authenticates the user and returns a signed **ID token** containing identity claims. SURFconext (academic SSO) and Google sign-in are wired in today; **Centerdata fits the same pattern**, with no bespoke mobile or LISS-specific flow introduced.

In other words, what Centerdata implements is a standard OIDC IdP. Nothing about the contract is Eyra-specific.

## 4. The three Eyra ↔ Centerdata interfaces

From Eyra's perspective, Centerdata is **one external party** that we integrate with through three independent logical interfaces. We do not presume how Centerdata splits these internally — whether the OIDC, provisioning, and questionnaire endpoints are functions of the same system or live in separate services. That is Centerdata's call.

| # | Direction | Purpose | Protocol |
|---|-----------|---------|----------|
| 1 | Centerdata → Eyra | Pre-register participants and assignments | REST/JSON, OAuth 2.0 `client_credentials` |
| 2 | Eyra → Centerdata | Authenticate a LISS panelist at sign-in | OpenID Connect (Authorization Code + PKCE) |
| 3 | Eyra → Centerdata (and back) | Launch a questionnaire and receive completion | Signed launch URL + redirect callback |

Each interface is described in detail below.

---

## 5. Interface 1 — Provisioning API

### 5.1 Purpose

Centerdata pre-creates the LISS panelists and their assignments in Next **before any participant ever signs in**, so that a panelist who signs in for the first time immediately sees their assignments waiting.

### 5.2 Direction and authentication

**Direction:** Centerdata calls a REST API exposed by Eyra/Next. Eyra is the resource server.

**Authentication:** OAuth 2.0 **client_credentials** flow — the standard OAuth grant for machine-to-machine authentication, where no human user is involved and the calling service authenticates as itself.

- Eyra issues Centerdata a `client_id` + `client_secret` pair (one per environment: staging, production). The `client_id` is public; the `client_secret` is the shared secret Centerdata uses to prove its identity.
- Centerdata POSTs `client_id` + `client_secret` to Eyra's token endpoint and gets back a short-lived **access token**. It then presents that token as an `Authorization: Bearer <token>` header on every API call (a "Bearer" token because whoever holds it can use it — keep it confidential).
- Tokens are short-lived (≤ 1 hour). Centerdata refreshes as needed.

**Alternatives considered:**
- *Long-lived API key*: simpler, but harder to rotate and revoke. Rejected — `client_credentials` is the standard for service-to-service, and we already have to speak OAuth/OIDC for Interface 2.
- *Mutual TLS*: stronger transport-level auth, but operationally heavier and not needed for the threat model.

### 5.3 User identifier — the join key

Each user provisioned by Centerdata is identified by **two required fields**:

- `centerdata_sub` *(required, primary)* — the value of the OIDC `sub` claim that Centerdata will issue for this panelist at sign-in: a stable, never-reassigned identifier. This is the **primary join key**.
- `email` *(required)* — the panelist's email address. Used for display, notifications, and as a sanity check at first sign-in.

At first sign-in via OIDC, Eyra looks up the pre-registered Next user by matching the OIDC ID token's `sub` claim against the stored `centerdata_sub`. Email mismatch produces a warning but does **not** block the sign-in — this covers legitimate email changes at Centerdata.

**Rationale:** Email is mutable and occasionally reassigned; relying on email alone for the durable join would break the link when a panelist's email changes at Centerdata. The OIDC `sub` claim is defined by the OIDC spec as locally-unique to the IdP and never-reassigned, making it the canonical join key.

**Alternatives considered:**
- *Email-only matching*: simpler but fragile (see rationale above). Rejected.
- *`sub`-only matching*: cleaner but loses email as a sanity check and a human-meaningful display field at provisioning time. Rejected.

### 5.4 API surface (initial sketch)

The exact API contract is part of the implementation work and will be specified separately. As a starting sketch:

```
POST   /api/provisioning/v1/users             Pre-register a LISS panelist
PATCH  /api/provisioning/v1/users/{sub}       Update a pre-registered user
DELETE /api/provisioning/v1/users/{sub}       Deactivate a user
POST   /api/provisioning/v1/assignments       Create an assignment for one or more users
PATCH  /api/provisioning/v1/assignments/{id}  Update an assignment
DELETE /api/provisioning/v1/assignments/{id}  Withdraw an assignment
```

The API is generic — Centerdata is one client among others (future partners, the internal Next CLI). The `provisioning` scope and `v1` version are independent of any specific caller.

All requests/responses are JSON. All endpoints return standard HTTP status codes and a structured error body on failure.

## 6. Interface 2 — OIDC sign-in

### 6.1 Purpose

Authenticate a LISS panelist visiting Next (on web or in the mobile app), using Centerdata's OIDC IdP. After successful sign-in, Eyra has a Phoenix session for the participant, linked to the pre-registered Next user.

### 6.2 Flow

Standard OpenID Connect **Authorization Code with PKCE**. Identical for web and mobile.

Two concepts to keep in mind:

- **Authorization Code flow** — the OIDC flow where the IdP, after authenticating the user in the browser, returns a short-lived *authorization code* to the client (Eyra) via redirect. Eyra then exchanges that code for tokens by making a server-to-server `POST` to the IdP's token endpoint. The user-agent never sees the tokens.
- **PKCE** (Proof Key for Code Exchange, RFC 7636) — Eyra generates a one-time secret (`code_verifier`) at the start of the flow and sends only a hash of it (`code_challenge`) with the authorization request. To exchange the code, Eyra has to present the original verifier. An attacker who intercepts the code alone cannot use it.

Steps:

1. Participant clicks "Log in with LISS panel" inside a Next page (web browser or mobile WebView).
2. Next (the OIDC **Relying Party** — the client that consumes the IdP's assertions) constructs an authorization request and redirects the participant to Centerdata's `/authorize` endpoint.
3. On mobile, the redirect opens in an **in-app browser tab** — `ASWebAuthenticationSession` on iOS, **Custom Tabs** on Android. On web, the redirect happens in the same browser tab.
4. The participant authenticates at Centerdata.
5. Centerdata redirects back to Eyra's callback URL with an authorization code.
6. Eyra exchanges the code for tokens at Centerdata's `/token` endpoint and validates the ID token signature against Centerdata's **JWKS** (JSON Web Key Set — the set of public keys Centerdata publishes at a discoverable URL, used to verify ID token signatures).
7. Eyra looks up the pre-registered Next user by `id_token.sub == stored.centerdata_sub`, establishes a session, and redirects the participant back into the Next UI.

### 6.3 What Eyra needs from Centerdata

- OIDC discovery endpoint (`/.well-known/openid-configuration`) — so Eyra can auto-configure the endpoints, supported algorithms, and JWKS URI.
- A registered OIDC client for Eyra (`client_id`, `client_secret`), one per environment (staging, production).
- A list of permitted **redirect URIs** that Centerdata will accept. Eyra will provide them:
  - Web: `https://next.eyra.co/auth/liss/callback` (and equivalent for staging).
  - Mobile: same web URL — mobile shell uses universal links / app links on top of the same URL.

### 6.4 Required ID token claims

The ID token is a signed JWT (JSON Web Token — a signed, base64url-encoded JSON payload) whose body carries claims about the authenticated user.

| Claim | Required | Notes |
|-------|----------|-------|
| `sub` | yes | Subject — the IdP's stable, never-reassigned identifier for the user. Eyra's primary join key — must match the `centerdata_sub` from provisioning. |
| `email` | yes | Display + sanity check at first sign-in. |
| `email_verified` | recommended | True only if Centerdata has verified ownership. |
| `iss` | yes | Issuer — the IdP's identifier URL. Eyra checks it matches Centerdata's published issuer. |
| `aud` | yes | Audience — must contain Eyra's `client_id`, so the token can't be replayed against a different RP. |
| `iat` | yes | Issued-at timestamp. |
| `exp` | yes | Expiry timestamp — Eyra rejects expired tokens. |
| `nonce` | yes | A random value Eyra generates per authorization request and includes in the request; Centerdata echoes it back in the ID token. Eyra checks it matches, which prevents replay of a captured ID token. |

### 6.5 Mobile — same contract as web

From Centerdata's side, the mobile flow is **identical** to the web flow: same OIDC client, same `client_id`, same `redirect_uri`, same `/authorize` and `/token` endpoints. There is no separate mobile client registration to maintain.

Eyra absorbs the mobile/web difference internally — the OIDC flow stays server-side.

## 7. Interface 3 — Questionnaire launch

### 7.1 Purpose

When a logged-in LISS participant taps "Start" on an assignment that points at a Centerdata-hosted questionnaire, Next hands off to Centerdata, the participant completes the questionnaire, and control returns to Next with a completion signal.

### 7.2 Pre-condition

The participant is **already authenticated in Next** as a LISS panelist (Interface 2 has run). Questionnaire launch is therefore not an authentication step — it is an *identity assertion + launch context* handoff. Centerdata does not need to re-authenticate the user.

### 7.3 Proposed mechanism — signed launch URL

Eyra mints a short-lived signed URL pointing at Centerdata's questionnaire endpoint. The URL carries a JWT (signed, base64url-encoded JSON payload — same format as the OIDC ID token) with the following claims. The roles here are reversed from Interface 2: this time Eyra signs, Centerdata verifies.

| Claim | Purpose |
|-------|---------|
| `iss` | Issuer — Eyra's identifier URL; Centerdata uses this to fetch Eyra's public keys. |
| `aud` | Audience — identifies Centerdata as the intended recipient; prevents the token being replayed against a different system. |
| `centerdata_sub` | Identifies the participant using the `sub` Centerdata previously issued at sign-in. |
| `questionnaire_id` | Which questionnaire to load. |
| `assignment_id` | Eyra's assignment identifier (echoed back at completion). |
| `nonce` | One-time random value that Centerdata records to detect a replayed launch URL. |
| `iat`, `exp` | Issued-at and expiry timestamps. Short expiry (~ 60 seconds) so a leaked URL is useless almost immediately. |
| `return_url` | Where Centerdata should send the participant after completion. |

Centerdata validates the JWT signature against Eyra's public key (which Eyra publishes at `/.well-known/jwks.json` — same JWKS mechanism as in Interface 2, just with roles reversed), checks `aud`, `exp`, and `nonce`, then opens the questionnaire. On completion, Centerdata redirects the participant to `return_url`, with a signed completion payload (or a callback `POST` to a Next webhook — see open questions).

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
4. **Provisioning API direction.** We propose Centerdata calls an Eyra-exposed REST API authenticated with `client_credentials`. Does this fit Centerdata's operational model, or does Centerdata prefer Eyra to poll Centerdata endpoints?
5. **Questionnaire launch mechanism.** What signed-launch mechanism does Centerdata's questionnaire system already support — LTI 1.3, a bespoke JWT scheme, shared HMAC, or something else? We propose to align with whatever Centerdata already does rather than introduce a new contract.
6. **Questionnaire completion callback.** Does Centerdata support a server-to-server completion webhook in addition to the redirect, and what signing/auth does it expect?
7. **Account lifecycle signals.** How does Centerdata signal participant deactivation or removal (provisioning `DELETE`, periodic reconciliation, lifecycle webhook)?
8. **Per-pool client identities.** If Centerdata supports multiple panels (LISS primary, secondary, etc.) in the future, does each panel get its own OIDC client_id, or is one shared client identity with `scope`/claims used to distinguish them?

## 9. Diagrams

Four diagrams accompany this document, all generated from `workspace.dsl` (Structurizr DSL). Centerdata is modelled as a single external Software System throughout — its internal split is not assumed, and the diagrams therefore do not name any internal Centerdata component. See [`diagrams.md`](diagrams.md) for regeneration instructions.

- **Context** (`structurizr-Context.png`) — Participant, Eyra/Next, Centerdata, and the operators on each side.
- **Interface 1 — Provisioning** (`structurizr-Provisioning.png`) — Dynamic view: Centerdata pre-registers a participant and an assignment, authenticated via `client_credentials`.
- **Interface 2 — OIDC sign-in** (`structurizr-SignIn.png`) — Dynamic view: OIDC Authorization Code + PKCE flow, identical for web and mobile.
- **Interface 3 — Questionnaire launch** (`structurizr-QuestionnaireLaunch.png`) — Dynamic view: signed JWT launch URL, questionnaire completion, redirect + webhook return.

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
