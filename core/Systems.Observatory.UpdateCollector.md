# `Systems.Observatory.UpdateCollector`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/observatory/update_collector.ex#L1)

Collects Observatory updates during a transaction and dispatches them together.

This module uses the Process dictionary to collect LiveView updates that should
be dispatched together after a database transaction commits. This prevents race
conditions where LiveViews would query the database before changes are committed.

## Usage

    # In a Switch handler:
    Observatory.UpdateCollector.collect({:embedded_live_view, MyView}, [id], %{model: model})

    # In a Multi transaction:
    Multi.new()
    |> Multi.update(:model, changeset)
    |> Multi.run(:commit_observatory, fn _, _ ->
      Observatory.UpdateCollector.dispatch_all()
      {:ok, :dispatched}
    end)
    |> Repo.commit()

# `clear`

Clears all collected updates without dispatching them.

Useful for cleanup in error cases or tests.

# `collect`

Collects an Observatory update to be dispatched later.

Updates are stored in the Process dictionary and will be dispatched
when `dispatch_all/0` is called.

## Parameters
- `target` - The target tuple like `{:page, MyPage}` or `{:embedded_live_view, MyView}`
- `args` - Arguments for Observatory.Public.dispatch (typically [id] or [id, user_id])
- `message` - The message map to send

## Examples

    UpdateCollector.collect({:page, MyPage}, [model.id], %{model: model})
    UpdateCollector.collect({:embedded_live_view, MyView}, [id, user_id], %{model: model})

# `count`

Returns the count of currently collected updates.

Useful for testing and debugging.

# `current_transaction_id`

Returns the current process's PID for use as a transaction identifier.

This can be useful for debugging or when you need to explicitly manage
updates for different processes.

# `dispatch_all`

Dispatches all collected Observatory updates.

This is automatically called by `setup_after_commit/1` after the transaction commits.
Can also be called manually if needed.

## Examples

    # Manual dispatch (not recommended)
    Observatory.UpdateCollector.dispatch_all()

# `get_all`

Returns all currently collected updates.

Useful for testing and debugging to inspect what updates have been
collected but not yet dispatched.

## Examples

    iex> UpdateCollector.get_all()
    []

    iex> UpdateCollector.collect({:page, MyPage}, [1], %{model: model})
    iex> UpdateCollector.get_all()
    [{{:page, MyPage}, [1], %{model: model}}]

---

*Consult [api-reference.md](api-reference.md) for complete listing*
