# `Frameworks.GreenLight.Permissions`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/green_light/permissions.ex#L1)

The permissions module provides several functions that create permission
strings and `GreenLight.PermissionMap`s.

# `access_permission`

# `action_permission`

# `actions_permission_map`

# `grant`

# `grant`

# `grant_access`
*macro* 

# `grant_actions`
*macro* 

# `grants_permission_map`

The permission map of grants given as data: `{module, roles}` as for
`grant_access/2`, `{module, %{action => roles}}` as for `grant_actions/2`.
Raises when a permission is in `permission_map` already or granted twice: a
grant never widens another one silently. A grant that does widen one says so
with a third element, `{module, roles, widen: true}`, and adds its roles to
that permission; it raises when it widens no permission.

# `setup_permission_map`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
