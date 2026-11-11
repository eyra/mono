# `Systems.NextAction.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/next_action/_public.ex#L1)

The NextActions context.

# `auth_module`

# `clear_next_action`

# `count_next_actions`

# `create_next_action`

Creates a next action for the audience.

Options:
  * `:key` - distinguishes several next actions of the same type for one user
  * `:params` - passed to the action's `to_view_model/2`
  * `:priority` - `:high`, `:normal` (default) or `:low`; lists show higher
    priorities first. Creating an existing next action again increases its
    count and only changes its priority when `:priority` is given. Leave the
    option out instead of passing `nil`, which the changeset refuses.

# `create_next_actions`

Creates the same next action for every user in `user_ids` with batched
inserts, for audiences too large for `create_next_action/3`. Takes the same
options. Users who already have it get its count increased, as with
`create_next_action/3`.

No `{:next_action, :created}` signal is sent: open pages and menu counters
show the new next actions on their next load. Returns the number of rows
inserted or updated.

# `list_next_actions`

# `list_next_actions_by_type`

Lists all next actions of a specific type for a user.

# `next_best_action`

# `next_best_action!`

# `next_best_action_for_key`

Returns the next action for a specific key.

# `next_best_action_for_scope`

Returns the top next action for a user, scoped to a specific action module
and a set of key values (typically ids of the scoping object — assignments
in a project, pools in an org, etc.). Returns `nil` when nothing matches.

# `print_auth_roles`

# `to_view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
