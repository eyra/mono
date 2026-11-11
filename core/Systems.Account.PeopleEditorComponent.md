# `Systems.Account.PeopleEditorComponent`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/people_editor_component.ex#L1)

Reusable LiveComponent for managing a list of people (add/remove).

Features:
- Display list of current people with remove buttons
- Search by email to add new people
- Self-removal confirmation (when removing yourself)
- Sends `add_user` and `remove_user` events to parent

## Usage

    <.live_component
      module={Account.PeopleEditorComponent}
      id="people_editor"
      title="Members"
      people={@members}
      users={@available_users}
      current_user={@current_user}
    />

## Events sent to parent
- `{:add_user, %{user: user}}` - when a user is added
- `{:remove_user, %{user: user}}` - when a user is removed

---

*Consult [api-reference.md](api-reference.md) for complete listing*
