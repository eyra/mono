# `Frameworks.Signal.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/signal/_public.ex#L1)

# `auth_module`

# `dispatch`

# `dispatch!`

# Deprecated, replaced by control flow in intercept/2
#
# Implement intercept/2 in your Signal Handler like this instead:
#
# ```elixir
# def intercept({my_entity, :updated}, %{my_entity: my_entity}) do
#   my_tool = get_my_tool_by_my_entity!(my_entity)
#   {:continue, :my_tool, my_tool}
# end
# ```

# `multi_dispatch`

Send a signal as part of an Ecto Multi.
It automatically merges the message with the multi
changes.

## Options
  - `:name` - The operation name to use in the Multi (defaults to :dispatch_signal)
  - `:message` - Additional message data to merge with the Multi changes (defaults to %{})

## Examples
    multi
    |> Signal.Public.multi_dispatch({:user, :created})

    multi
    |> Signal.Public.multi_dispatch({:user, :updated}, name: :dispatch_user_signal)

    multi
    |> Signal.Public.multi_dispatch({:user, :deleted},
        name: :dispatch_delete_signal,
        message: %{deleted_by: admin_id})

# `multi_dispatch`

# `print_auth_roles`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
