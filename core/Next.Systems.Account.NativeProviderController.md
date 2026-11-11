# `Next.Systems.Account.NativeProviderController`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/account/native_provider_controller.ex#L1)

The pages the Next native apps open in the system sign-in sheet to sign in
through an identity provider; see `Next.Systems.Account.NativeHandoff`.

# `auth_module`

# `callback`

The app's callback URL. The sheet catches it before it loads, so a browser
only gets here when it opens the link itself.

# `print_auth_roles`

# `start`

Marks the sheet with the app's code challenge and continues at Mica's own
start of the provider. `login_hint` preselects the account where the
provider supports it; `return_to` comes back from the redeem.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
