# `Systems.Pool.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/pool/_public.ex#L1)

# `add_participant!`

# `add_to_pool`

# `add_user_to_panl_pool`

# `auth_module`

# `can_manage?`

Whether `user` can manage `pool` from the Pool Admin page.

System admins can manage any pool. Otherwise the user must be an owner
of the org that the pool belongs to.

# `copy`

# `count_eligitable_users`

# `create!`

# `get`

# `get!`

# `get_by_name`

# `get_by_names`

# `get_by_slug`

# `get_by_submission!`

# `get_or_create_budget`

# `get_panl`

# `get_submission!`

# `get_tag`

# `list`

# `list_active`

# `list_by_director`

# `list_by_org`

# `list_by_orgs`

# `list_by_participant`

# `list_directors`

# `list_owned`

# `list_participant_ids`

# `list_participants`

# `list_participants_with_added_at`

Like `list_participants/2` but returns `{user, added_at}` tuples where
`added_at` is the timestamp at which the `:participant` role was granted
on the pool's auth_node.

# `list_submissions`

# `list_submissions`

# `participant?`

# `prepare_submission`

# `print_auth_roles`

# `published_status`

# `remove_participant`

# `select`

# `submit`

# `target_achieved?`

# `update`

# `update!`

# `update_pool_participations`

# `wallet_related?`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
