# `Systems.Admin.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/admin/_public.ex#L1)

# `admin?`

# `admin?`

# `admin_access?`

Checks if a user has access to admin features.

A user has admin access if they are either:
- A system admin (matches admin email patterns)
- An owner of at least one governable entity (org, pool, etc.)

# `auth_module`

# `compile`

# `get_client`

The client with the given id, or `nil`.

# `get_client_assignment`

One project assignment with its client and team (owners), or `nil`.

# `has_governable_entities?`

Checks if a user owns any governable entities.

Uses the configured list of entity checkers to determine if the user
owns at least one entity of any governable type.

# `list_client_activity`

Clients with the number of their project assignments under the given filters,
ordered by assignment count (most first).

# `list_client_assignments`

The project assignments of one client under the given filters, newest first.

# `list_matching_users`

The users that match every filter in `filters` (`Systems.Admin.UserFilters`)
and every word in `query` (in the email or full name, case-insensitive),
sorted by label, with their profile preloaded. This is the matching of the
Admin → Users tab.

Filters combine with AND, so `:verified` together with `:unverified` matches
nobody. A `nil` or empty query matches everyone. Affiliate and pool
membership are looked up with one query per filter, not one per user.

# `print_auth_roles`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
