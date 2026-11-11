# `Next.Systems.Account.NativeSigninGuard`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/account/native_signin_guard.ex#L1)

Admits only same-origin JSON requests from the Next native apps to the
native sign-in calls.

The calls carry and set the session cookie, so they need CSRF protection.
They are made with `fetch` from a hidden WKWebView that has a document on
Mica's origin, so instead of a CSRF token they require:

  * an `Origin` header naming the host the request was sent to, and no
    cross-site `Sec-Fetch-Site`;
  * `Content-Type: application/json`, which no HTML form can send and which
    makes any cross-origin `fetch` preflight, which Mica never grants.

The `NextApp/<version> iOS|Android` user agent keeps the calls to the apps;
browsers sign in through the LiveView pages. It is not a security control.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
