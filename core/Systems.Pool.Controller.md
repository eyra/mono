# `Systems.Pool.Controller`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/pool/controller.ex#L1)

Phoenix controller for Pool-scoped HTTP entry points that are not
themselves LiveViews.

Currently exposes:

  * `join/2` — gate at `/pool/:slug/join`. Resolves the slug, checks
    whether the current user is already a participant, and either
    forwards to the pool-scoped onboarding LiveView or redirects
    home.

# `auth_module`

# `join`

# `print_auth_roles`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
