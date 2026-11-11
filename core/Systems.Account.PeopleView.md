# `Systems.Account.PeopleView`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/people_view.ex#L1)

DEPRECATED: Use `Systems.Account.PeopleEditorComponent` instead.

This component uses the legacy Fabric framework. New code should use
`PeopleEditorComponent` (LiveComponent) which works with LiveNest.

## Migration Guide

1. Replace `PeopleView` with `PeopleEditorComponent` in your view:

    <.live_component
      module={Account.PeopleEditorComponent}
      id="people_editor"
      title={@vm.title}
      people={@vm.people}
      users={@vm.users}
      current_user={@current_user}
    />

2. Handle events in parent LiveView:

    def handle_info({:add_user, %{user: user}}, socket) do
      # Persist the addition
      {:noreply, update_view_model(socket)}
    end

    def handle_info({:remove_user, %{user: user}}, socket) do
      # Persist the removal
      {:noreply, update_view_model(socket)}
    end

3. For modal usage, see `Systems.Account.PeopleEditorModalView`.

# `add_child`

# `async`

# `auth_module`

# `compose_child`

# `compose_element`

# `flash_error`

# `flash_error`

# `flash_info`

# `flash_persister_error`

# `flash_persister_error`

# `flash_persister_saved`

# `handle_info`

# `hide_flash`

# `print_auth_roles`

# `reset_fabric`

# `save`

# `save_closure`

# `update_child`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
