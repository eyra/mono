# `Systems.Account.PeopleEditorModalView`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/people_editor_modal_view.ex#L1)

Modal LiveView for managing people (add/remove).

Wraps PeopleEditorComponent in a modal context.

## Session params
- `title` - The modal title
- `people` - List of current people (users with :profile preloaded)
- `users` - List of available users to add (users with :profile preloaded)
- `current_user` - The current user (for self-removal confirmation)

## Callbacks
Override `handle_add_user/2` and `handle_remove_user/2` in the parent
to persist changes.

# `handle_add_user`

```elixir
@callback handle_add_user(
  user :: Systems.Account.User.t(),
  socket :: Phoenix.LiveView.Socket.t()
) ::
  Phoenix.LiveView.Socket.t()
```

# `handle_remove_user`

```elixir
@callback handle_remove_user(
  user :: Systems.Account.User.t(),
  socket :: Phoenix.LiveView.Socket.t()
) ::
  Phoenix.LiveView.Socket.t()
```

# `consume_event`

# `handle_consumed_event`

# `handle_info`

# `hide_modal`

# `observe_view_model`

# `present_modal`

# `put_info_flash`

# `put_saved_info_flash`

# `put_updated_info_flash`

# `update_view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
