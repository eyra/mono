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
