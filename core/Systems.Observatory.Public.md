# `Systems.Observatory.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/observatory/_public.ex#L1)

# `auth_module`

# `clear_updates`

Clears all collected Observatory updates without dispatching them.

This is useful in error cases where you want to abandon collected updates.

## Examples

    Observatory.Public.clear_updates()

# `collect_update`

Collects an Observatory update to be dispatched later within a transaction.

This is a convenience wrapper around UpdateCollector.collect/3.
Use this when you want to defer LiveView updates until after a transaction commits.

## Examples

    Observatory.Public.collect_update({:page, MyPage}, [id], %{model: model})
    Observatory.Public.collect_update({:embedded_live_view, MyView}, [id, user_id], %{model: model})

# `commit_updates`

Commits all collected Observatory updates by dispatching them.

This is a convenience wrapper around UpdateCollector.dispatch_all/0.
Call this after your transaction commits to send all collected updates.

## Examples

    Multi.run(multi, :commit_observatory, fn _, _ ->
      Observatory.Public.commit_updates()
      {:ok, :committed}
    end)

# `dispatch`

# `get_view_model`

# `local_dispatch`

# `observe`

# `print_auth_roles`

# `subscribe`

# `update_view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
