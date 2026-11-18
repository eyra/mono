# `Frameworks.GreenLight.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/green_light/_public.ex#L1)

Defines an authorization module.

When used, the authorization module expects a list of possible roles.

An authorization module defines all the permissions with their role mappings.
Permissions are defined by using the grant_* helpers
(`Frameworks.GreenLight.Permissions.grant_access/2`,
`Frameworks.GreenLight.Permissions.grant_actions/2`).

The `grants: {module, function, args}` option adds grants given as data at
runtime (see `Frameworks.GreenLight.Permissions.grants_permission_map/2`).
`permission_map/0` merges them into the compiled grants on its first call and
caches the result until the node restarts or the compiled grants change.

# `auth_module`

# `print_auth_roles`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
