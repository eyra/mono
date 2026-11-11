# `Next.Systems.Account.NativeHandoff`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/account/native_handoff.ex#L1)

Hands a sign-in through an identity provider back to the Next native apps.

The app opens the provider in the system sign-in sheet, which keeps its own
cookies. `NativeProviderController.start/2` marks the sheet with a cookie
that holds the provider and the app's code challenge. When that provider's
flow signs the user in, `hand_off/4` redirects the sheet to the app's
callback URL with a one-time token instead of starting a session there; when
it ends without signing in, `hand_off_unfinished/3` sends the result there.
Other sign-ins in the same browser are left alone. The app redeems the token
in its own web view (`NativeSigninController.redeem/2`) together with the
code verifier.

See the "Identity providers in the sign-in sheet" section of
`docs/architecture/mobile/designs/authentication-session.md`.

# `callback_url`

The app's callback URL, on Mica's own host; the sheet catches it before it
loads.

# `redeem`

Redeems a token of `hand_off/4` with the app's code verifier. The token is
used up by the first attempt, whether the verifier matches or not.

# `return_error`

Sends the sheet back to the app with an `error` instead of a token.

# `start`

Marks the sheet: the next sign-in through `provider` in it goes back to the app.

# `valid_code_challenge?`

Whether `code_challenge` is a Base64url SHA-256 digest, as `S256` sends it.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
