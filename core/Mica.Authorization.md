# `Mica.Authorization`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/authorization.ex#L1)

The authorization system for Mica.

It makes use of the GreenLight framework to manage permissions and
authorization.

# `allowed?`

# `assign_role`

Assign a role by piping the result of an Ecto insert operation directly into
this function.

# `build_role_assignment`

# `can?`

```elixir
@spec can?(any(), Frameworks.GreenLight.PermissionMap.permission()) :: boolean()
```

# `can?`

# `can?`

# `can_access?`

# `can_access?`

# `copy`

# `copy`

# `copy_auth_node`

# `copy_auth_node`

# `copy_role`

# `create_node`

# `create_node!`

# `delete_role_assignments`

# `get_node!`

# `get_parent_nodes`

# `link`

# `link`

# `link`

# `list_principals`

# `list_roles`

# `permission_map`

# `possible_roles`

# `prepare_node`

# `prepare_node`

# `prepare_node`

# `prepare_role`

# `prepare_role`

# `print_roles`

# `query_node_ids`

# `query_principal_ids`

# `query_role_assignment`

# `remove_role!`

# `role_assignment_schema`

# `roles_intersect?`

# `user_has_role?`

# `users_with_inherited_role`

Users with `role` assigned on the auth node of `entity` or on any of its ancestors.

This mirrors the inheritance applied by `can?/3` and `roles_intersect?/3`: a role
granted on a parent node applies to everything below it. Prefer this over
`users_with_role/3` whenever the role lives higher up the tree than the entity
being asked about, e.g. the `:owner` of an assignment, which is assigned on the
project node.

An integer argument is interpreted as an auth node id, not as an entity id.

# `users_with_role`

Users with `role` assigned directly on the auth node of `entity`.

Role assignments on ancestor nodes are ignored. Use `users_with_inherited_role/3`
when the role is expected to be inherited from higher up the tree, the way
`can?/3` resolves it.

An integer argument is interpreted as an auth node id, not as an entity id.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
