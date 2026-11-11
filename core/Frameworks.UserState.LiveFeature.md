# `Frameworks.UserState.LiveFeature`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/user_state/live_feature.ex#L1)

LiveView feature for persisting user state changes.

Provides `publish_user_state_change/3` to persist state changes directly
to localStorage via JavaScript push_event.

## Usage

Add to your LiveView:

    use Frameworks.UserState.LiveFeature

Then call `publish_user_state_change/3` to persist state:

    socket
    |> publish_user_state_change(:chapter, chapter_id)

## Namespacing

State is namespaced via `user_state_namespace` in live_context:

    context = LiveContext.extend(context, %{
      user_state_namespace: [:manual, manual_id]
    })

This results in storage key: `[:manual, 123, :chapter]`

# `publish_user_state_change`

Persists a user state change to localStorage.

Extracts the namespace from `socket.assigns.live_context[:user_state_namespace]`,
builds the full path, and sends to JavaScript via push_event.

## Examples

    # When preparing child's live_context:
    context = LiveContext.extend(context, %{
      user_state_namespace: [:crew, crew.id]
    })

    # In View:
    socket
    |> publish_user_state_change(:task, task_id)

    # Persists to localStorage with key built from [:crew, 123, :task]

---

*Consult [api-reference.md](api-reference.md) for complete listing*
