# `Next.Systems.WellKnown.Controller`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/well_known/controller.ex#L1)

Serves the apple-app-site-association file, so iOS opens invitation links
(`/assignment/*`) in the Next app (UC-SENSE-03), and so the sign-in sheet may
hand an identity-provider sign-in back to the app on this host
(`webcredentials`, see `Next.Systems.Account.NativeHandoff`).

Both app IDs are listed on every environment: iOS only links a domain to an
app whose Associated Domains entitlement names that domain, so the Dev app
(`co.eyra.next.dev`) never claims links on other environments. Local, Staging,
and Prod builds share `co.eyra.next`.

# `apple_app_site_association`

# `auth_module`

# `print_auth_roles`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
