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
/user/auth/identify?session_event=logged_out
```

The first-party page asset dispatches exactly one WebKit message:

```json
{ "type": "logged_out" }
```

It then removes `session_event` from the URL with `history.replaceState`, which
prevents repeat delivery. The native shell moves to checking and reruns the
status request.

There are no other session bridge events: neither login nor startup uses the
bridge.

## WebKit bridge

Core posts the logout message to:

```javascript
window.webkit.messageHandlers.Native.postMessage({ type: "logged_out" })
```

The native shell registers its `WKScriptMessageHandler` as `Native`, accepts
messages only from the configured Next origin in the main frame, and accepts only
the `logged_out` event.

## Consequences

- Server-side status, rather than URL shape or native state, determines whether a
  session is authenticated.
- A stale, revoked, or expired cookie cannot open native tabs.
- Native code never handles session material.
- Login needs no custom browser-to-native protocol; logout has one explicit
  lifecycle event because it occurs from a retained authenticated WebView.
