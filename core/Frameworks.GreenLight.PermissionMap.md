# `Frameworks.GreenLight.PermissionMap`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/green_light/permission_map.ex#L1)

The permission map holds a mapping of permissions to roles. The permission map
is intended to be an implementation detail of the authorization framework.
Convenience functions to build it are provided in other modules.

# `permission`

```elixir
@type permission() :: binary()
```

# `role`

```elixir
@type role() :: atom()
```

# `role_enum`

```elixir
@type role_enum() :: role_set() | role_list()
```

# `role_list`

```elixir
@type role_list() :: [role()]
```

# `role_set`

```elixir
@type role_set() :: MapSet.t(role())
```

# `t`

```elixir
@opaque t()
```

# `allowed?`

```elixir
@spec allowed?(t(), permission(), role() | role_list()) :: boolean()
@spec allowed?(t(), binary(), role_set()) :: boolean()
```

Returns wheter or not a the given set of roles should be allowed for the given
permission.

# `grant`

```elixir
@spec grant(t(), permission(), role() | role_list()) :: t()
```

Add a mapping for the given role and permission if does not already exist.

# `list_permission_assignments`

# `merge`

```elixir
@spec merge(t(), t()) :: t()
```

Merge two permission maps. The result of the merge is a permission map for
which a permission that is available in either (or both) maps has the combined
roles of both permission maps.

# `new`

```elixir
@spec new() :: t()
```

# `new`

```elixir
@spec new(%{required(permission()) =&gt; role_enum()}) :: t()
```

# `new_t`

```elixir
@spec new_t(any()) :: t()
```

This constructor is here to appease Dialyzer when a PermissionMap is used as a module attribute.

# `roles`

```elixir
@spec roles(t(), permission()) :: role_set()
```

Return a `MapSet` of roles for a given permission. This always returns a
`MapSet` (might be empty).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
