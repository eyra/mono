# Native authentication session design

## Problem

The Next iOS shell must decide whether to show native tabs or the Identify / OTP
WebView before it presents either. The persistent credential must survive an app
force-quit but must never be exposed to Swift, Kotlin, or a native bridge.

## Decision

Core remains the sole authority for authentication state. The native shell uses
WebKit only as an opaque cookie holder and receives coarse state from Core:

```text
GET /user/auth/status
```

| Response | Meaning | Native transition |
| --- | --- | --- |
| `204 No Content` | Valid authenticated session | Build the native tab shell |
| `401 Unauthorized` | Missing, revoked, or expired session | Show the Identify / OTP WebView |
| Transport failure or another response | State cannot be determined | Keep the launch cover visible and offer Retry |

Responses have an empty body and `Cache-Control: no-store`.

## Credential boundary

The status request runs in a non-visible `WKWebView` using
`WKWebsiteDataStore.default()` and the `NextApp/<version> iOS` user-agent suffix.
The native shell MUST NOT read, copy, persist, or send the signed HttpOnly cookie
value. It MUST NOT use `URLSession` for the status request.

Core validates the signed cookie and opaque server-side token. A mobile token has
separate creation and activity timestamps. It expires after 60 days of
inactivity; a valid status request renews both its activity timestamp and its
persistent cookie expiry.

## Lifecycle

### Startup

1. Show the launch cover in a checking state.
2. Run the hidden WebKit status request.
3. Transition only from its `204`, `401`, or failure response.

### OTP completion

Core follows its normal authenticated redirect. It does not emit an
`authenticated` bridge event.

The visible authentication WebView observes its first top-level same-origin
navigation outside `/user/auth/...`. That navigation is only a trigger to return
the native shell to checking and rerun `/user/auth/status`; it MUST NOT itself
promote the native shell to authenticated.

### Explicit logout

For a `NextApp/<version> iOS` request, Core revokes the server token, clears the
persistent cookie, and redirects to:

```text
/user/auth/identify
```

The retained account WebView's navigation to Identify is the logout handoff. The
native shell returns to authentication bootstrap and determines the resulting
state through `/user/auth/status`.

There is no Core-to-native bridge. Neither login, startup, nor logout posts a
WebKit message.

## Consequences

- Server-side status, rather than URL shape or native state, determines whether a
  session is authenticated.
- A stale, revoked, or expired cookie cannot open native tabs.
- Native code never handles session material.
- Authentication lifecycle state needs no custom browser-to-native protocol.

## Native sign-in

UC-SENSE-09 replaces the Identify / OTP WebView with a native Sign-in screen
(email, then code). Core offers two JSON calls for it. They follow the
participant path of the web flow (`/user/auth/identify/participant`, then
`/user/auth/verify`) and keep the credential boundary above: the session is still
the signed HttpOnly cookie in WebKit's default data store, and no response body
carries a credential.

### Calling convention

The app makes both calls with `fetch` from a non-visible `WKWebView` using
`WKWebsiteDataStore.default()` and the `NextApp/<version> iOS` user-agent
suffix, from a document on Core's origin, with `credentials: "same-origin"`.
Native code passes the email and code into the WebView and reads back the JSON
body; it never sees a cookie. It MUST NOT use `URLSession`.

Every call needs:

| Header | Value |
| --- | --- |
| `Content-Type` | `application/json` |
| `Origin` | Core's origin (the browser sets it) |
| `User-Agent` | ends in `NextApp/<version> iOS` (or `Android`) |

All responses are JSON with `Cache-Control: no-store`. Errors are
`{"error": "<code>"}`; the app maps each code to its own copy.

### Identify

The same step as the web flow's identify page: the app sends the email, and
Core either emails a code or names the identity provider to continue with.

```text
POST /user/auth/native/identify
{"email": "participant@example.com", "return_to": "/assignment/1"}
```

`return_to` is optional. Core keeps it only when it is a same-site path: it
starts with a single `/` (not `//` or `/\`) and has no control characters.
Any other value is dropped, as if no `return_to` was sent. The same rule applies
in the web flow.

| Status | Body | Meaning |
| --- | --- | --- |
| `200` | `{"next": "code"}` | A code was emailed; show the code step. Same answer for known and unknown emails. |
| `200` | `{"next": "identity_provider", "provider": "google", "url": "/auth/google?login_hint=…"}` | The account signs in with an identity provider (`google`, `surfconext`). Continue in the sign-in sheet with `provider` (see [Identity providers in the sign-in sheet](#identity-providers-in-the-sign-in-sheet)); `url` is the web flow's start, for app versions that open it in a WebView. |
| `422` | `{"error": "invalid_email"}` | Not an email address. |
| `422` | `{"error": "unsupported_account"}` | The account signs in only through a panel provider (Centerdata), never by email. |
| `429` | `{"error": "rate_limited"}` | Too many codes requested for this email. |

### Verify the code

```text
POST /user/auth/native/verify
{"email": "participant@example.com", "code": "123456", "return_to": "/assignment/1"}
```

| Status | Body | Meaning |
| --- | --- | --- |
| `200` | `{"onboarding": false, "redirect_to": null}` | Signed in. The session cookie is set on this response. |
| `200` | `{"onboarding": true, "redirect_to": "/user/onboarding"}` | Signed in as a new participant, who still has to go through onboarding at `redirect_to`. |
| `422` | `{"error": "invalid_code"}` | Wrong code; the attempt is counted. The user may try again. |
| `422` | `{"error": "code_expired"}` | No valid code for this email (expired, used, or never requested). Identify again for a new code. |
| `422` | `{"error": "too_many_attempts"}` | The code is locked after too many wrong attempts. Identify again for a new code. |
| `422` | `{"error": "invalid_email"}` | The code was right, but no account could be created for the email (for example, another sign-in registered it in the meantime). Identify again for a new code. |

`redirect_to` is `/user/onboarding` (with the kept `return_to` appended) for a
new user, the kept `return_to` for an existing user, or `null` when there is
nowhere to go but the native tabs. It is always a same-site path, so the app
resolves it against Core's origin. After a `200` the app reruns `GET /user/auth/status`, as at
startup, and only that `204` opens the native shell.

### Errors shared by both calls

| Status | Body | Meaning |
| --- | --- | --- |
| `400` | `{"error": "invalid_request"}` | `email` (or `code`) missing or not a string. |
| `403` | `{"error": "forbidden"}` | `Origin` missing or another host, or `Sec-Fetch-Site` not `same-origin`. |
| `415` | `{"error": "unsupported_media_type"}` | Not `application/json`. |
| `403` | `{"error": "unsupported_client"}` | No `NextApp/<version> iOS` or `Android` user agent. |
| `404` | `{"error": "unavailable"}` | OTP sign-in (`otp` feature) is off. |

A body that is not valid JSON is rejected before these checks with a plain
`400`. With `Accept: application/json` its body is `{"error": "Bad Request"}`;
the app can treat it like `invalid_request`.

### Session and cookie

Verifying signs the user in the same way the web flow's redeem step does for a
`NextApp` request: a `mobile_session` token (60 days of inactivity), the session
renewed against fixation, and the persistent signed HttpOnly `SameSite=Lax`
cookie. WebKit stores it from the `fetch` response, so the web pages in the app
(Account included) and `GET /user/auth/status` see the same session. The web
flow's short-lived redeem token is not needed: the verify call answers with the
cookie itself.

### CSRF

The calls carry and set the session cookie, so a hostile page must not be able
to call them in a user's browser (for example to sign them into the attacker's
account). They do not use Phoenix's CSRF token, which would need an extra round
trip to fetch the token. Instead:

- `Origin` must name the host the request was sent to, and `Sec-Fetch-Site`,
  when sent, must be `same-origin`.
- `Content-Type` must be `application/json`. No HTML form can send that, and a
  cross-origin `fetch` with it needs a CORS preflight, which Core never grants.

Either check alone stops a cross-site request; together they are the
"verify origin" and "custom request header" defences for JSON endpoints. The
`SameSite=Lax` cookie adds a layer in browsers that follow RFC 6265bis: they
neither send nor store it on a cross-site `fetch`.

### Clients

The calls answer only requests with the `NextApp` user agent. They create mobile
sessions, and browsers already sign in through the LiveView pages, so there is no
second browser sign-in path. The user agent is not a security control.

### Rules shared with the web flow

Both flows use the same code and session functions, so they cannot drift apart:

- Codes: 6 digits, valid for 10 minutes, 5 wrong attempts per code; requesting a
  new code replaces the old one (`Account.AuthCodeModel`, `Account.Public`).
- Rate limit: 3 code requests per email per minute (`:otp_request`), the same
  limiter the web flow uses. Verifying has no other limit than the attempts per
  code, as on the web.
- Routing: `Account.EmailRouter` decides between a code and an identity
  provider; known and unknown emails both get a code, so the calls reveal no more
  about an email than the web flow (which also redirects identity-provider
  accounts to their provider).
- Users: unknown emails are registered as participants (`creator: false`); a
  provisional user (one that never had a real email) signed in on the same
  session gets the email linked instead (`Next.Account.OtpSignin`). External and
  affiliate sessions are signed out first (`Systems.Account.Plug`), as on the
  web, so the email is never linked into them.
- `return_to`: same-site paths only (`CoreWeb.ReturnTo.sanitize/1`).
- The code email is the web flow's, in the locale from the session or
  `Accept-Language`.

### Where the code lives

The mobile session and the `NextApp` client are Next's, so the calls live in
Next: `Next.Account.NativeSigninController`, `Next.Account.NativeSigninGuard`
(CSRF and client checks) and `Next.Account.OtpSignin` (steps shared with the
LiveView pages and the redeem step), in `next/systems/account/`. Their routes and
the `:native_signin` pipeline are in `Next.Account.System`. In Mica,
`Account.UserAuth.log_in_user_without_redirect/3` starts a session of the
requested type without redirecting, and `CoreWeb.ReturnTo.sanitize/1` keeps only
same-site paths.

## Identity providers in the sign-in sheet

The app opens identity providers (Google, SURFconext, Centerdata) in Apple's
system sign-in sheet (`ASWebAuthenticationSession`), not in its own WebView:
Google refuses OAuth in embedded WebViews, and the sheet shows the provider's
real address and the user's saved sign-ins. The sheet has Safari's cookies, not
the app's, so Core does not sign the user in there. It hands the sign-in back
to the app with a one-time token, which the app redeems in its own WebView with
a PKCE-style code verifier (RFC 7636, `S256`).

1. The app makes a code verifier and opens Core's start URL, with the
   verifier's challenge, in the sheet.
2. Core marks the sheet with a cookie and continues at its own start of the
   provider.
3. After the provider's callback, Core redirects the sheet to the app's callback
   URL with a token, instead of signing in there. The sheet catches the URL and
   closes.
4. The app redeems the token with the verifier from its hidden WebView. Core sets
   the session cookie, and `GET /user/auth/status` answers `204`.

### Start

The app generates a random `code_verifier` (43 to 128 characters of
`[A-Za-z0-9-._~]`) and sends its challenge,
`base64url(sha256(code_verifier))` without padding:

```text
GET /user/auth/native/provider/<provider>?code_challenge=<challenge>&code_challenge_method=S256
    [&login_hint=<email>][&return_to=<path>]
```

- `provider`: `google`, `surfconext` or `centerdata` (and `mock` where Core has
  test sign-in). Identify answers the provider of an email account; the app may
  also offer provider buttons.
- `login_hint`: preselects the Google account (the email the user typed).
- `return_to`: kept like the native calls' `return_to`, and returned by redeem.

Core sets a signed `_next_native_sign_in` cookie (10 minutes, HttpOnly,
`SameSite=Lax`) holding the challenge and `return_to`, and redirects to its own
start of the provider. Everything after that is the web flow: the provider, its
callback, and the move-your-account page when the email already has an account
with another sign-in method.

### Callback

Where the web flow would sign the user in and redirect, a sheet with the cookie
is instead redirected to the callback URL on Core's own host, and the cookie is
removed. The sheet keeps no Core session.

```text
https://<core host>/user/auth/native/callback?token=<token>
https://<core host>/user/auth/native/callback?error=<code>
```

The app starts the sheet with
`ASWebAuthenticationSession.Callback.https(host: <core host>, path: "/user/auth/native/callback")`
(iOS 17.4+). An `https` callback on Core's host is used rather than a custom URL
scheme: iOS only gives it to the app whose Associated Domains entitlement lists
`webcredentials:<core host>` and which Core's `apple-app-site-association`
names under `webcredentials`, while any app can register a custom scheme. Core
serves `webcredentials` for `co.eyra.next` and `co.eyra.next.dev`. A browser
that opens the callback URL itself is sent to `/user/signin`.

| `error` | Meaning |
| --- | --- |
| `invalid_request` | Unknown provider, or `code_challenge` missing, not `S256`, or not 43 Base64url characters. |
| `unavailable` | The provider is off on this Core. |
| `failed` | The sign-in ended on Core's sign-in page with an error: the provider's state was lost or the account could not be registered. |
| `cancelled` | The sign-in ended on Core's sign-in pages without an error, for example when the user declined moving their account to the provider. |

When the user closes the sheet, the app gets
`ASWebAuthenticationSessionError.canceledLogin` from iOS and nothing from Core.

### Redeem

Within 2 minutes, from the hidden WebView with the [calling
convention](#calling-convention) of the native calls:

```text
POST /user/auth/native/redeem
{"token": "<token>", "code_verifier": "<code_verifier>"}
```

| Status | Body | Meaning |
| --- | --- | --- |
| `200` | `{"onboarding": false, "redirect_to": "/assignment/1"}` | Signed in, as after Verify the code: the session cookie is set on this response. |
| `200` | `{"onboarding": true, "redirect_to": "/user/onboarding?return_to=…"}` | Signed in as a user the provider sign-in registered, who still has to go through onboarding at `redirect_to`. |
| `422` | `{"error": "token_expired"}` | Older than 2 minutes. Start again. |
| `422` | `{"error": "token_used"}` | Already redeemed, or replaced by a newer sign-in of the same user. Start again. |
| `422` | `{"error": "verifier_mismatch"}` | `code_verifier` does not match the challenge. The token is used up. |
| `422` | `{"error": "invalid_token"}` | Not a token Core issued. |
| `400` | `{"error": "invalid_request"}` | `token` or `code_verifier` missing or not a string. |

`403` and `415` answer as for the other native calls. Redeem works whether or
not the `otp` feature is on. `redirect_to` follows the rules of Verify the code.

The token is single-use: the first redeem deletes it, whatever its outcome. An
account is never matched against `login_hint`: like the web flow, the app is
signed in to the account the provider returned. After a `200` the app reruns
`GET /user/auth/status`, and only that `204` opens the native shell.

### Where this code lives

In Next: `Next.Account.NativeProviderController` (start and callback URL),
`Next.Account.NativeHandoff` (the cookie, the token, and the redeem checks),
`Next.Account.NativeSheetReturn` (the `cancelled` and `failed` results on the
sign-in pages) and `NativeSigninController.redeem/2`. Mica's
`Account.UserAuth.log_in_user/4` asks the SaaS's sign-in handoffs
(`Core.System.sign_in_handoffs/0`, `Systems.Account.SignInHandoff`) before it
starts a session, and `Account.Public.generate_one_time_token/2` and
`take_one_time_token/3` keep the single-use half of the token in `users_tokens`.
