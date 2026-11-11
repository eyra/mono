# `Systems.Advert.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/advert/_public.ex#L1)

The Studies context.

# `all`

# `assign_owners`

# `auth_module`

# `change`

# `completed?`

# `copy`

# `create`

Creates a advert.

# `delete`

# `get!`

# `get_by_assignment`

# `get_by_promotion`

# `get_by_submission`

# `get_changeset`

# `get_user_pools_by_currency`

# `handle_exclusion`

# `import_participant_reward`

# `import_participant_reward_exists?`

# `list`

# `list_by_assignments`

# `list_by_fund`

# `list_by_participant`

Returns the list of adverts where the user has the specified role

# `list_by_pool_and_status`

# `list_by_pools_and_submission_status`

# `list_by_status`

# `list_excluded_adverts`

# `list_excluded_user_ids`

# `list_owners`

# `list_submitted`

Returns the list of adverts submitted at least once.

# `list_tools`

# `list_tools`

# `mark_expired_debug`

  Marks expired tasks in online adverts based on updated_at and estimated duration.
  If force is true (for debug purposes only), all pending tasks will be marked as expired.

# `mark_expired_debug`

  Marks expired tasks in given advert

# `open_spot_count`

# `pool_visibility`

# `print_auth_roles`

# `query_user_pools_by_currency`

# `ready?`

# `reward_amount`

# `reward_value`

# `rewarded_amount`

# `submission_updated`

# `update`

Updates a get_advert.

## Examples

    iex> update(get_advert, %{field: new_value})
    {:ok, %Advert.Model{}}

    iex> update(get_advert, %{field: bad_value})
    {:error, %Ecto.Changeset{}}

# `update`

# `user_has_currency?`

# `validate_open`

# `validate_open`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
