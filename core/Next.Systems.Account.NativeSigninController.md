# `Next.Systems.Account.NativeSigninController`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/account/native_signin_controller.ex#L1)

JSON calls behind the native Sign-in screen of the Next apps: identify
(send a sign-in code to an email, or point to its identity provider), then
verify the code; or redeem the token of an identity-provider sign-in (see
`Next.Systems.Account.NativeHandoff`). They follow the participant
path of the LiveView flow (`AuthIdentifyPage`, `AuthCodeVerifyPage`, the
redeem step) and share its steps through `Next.Systems.Account.OtpSignin`.

Verifying starts a mobile session and sets its cookie on the response;
the body carries no credential. See the "Native sign-in" section of
`docs/architecture/mobile/designs/authentication-session.md`.

# `auth_module`

# `identify`

# `print_auth_roles`

# `redeem`

Redeems the token an identity-provider sign-in in the sign-in sheet sent to
the app's callback URL (`Next.Systems.Account.NativeHandoff`), with the code
verifier of the challenge the app started it with.

# `verify_code`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
