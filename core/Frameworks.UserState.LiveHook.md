# `Frameworks.UserState.LiveHook`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/user_state/live_hook.ex#L1)

LiveView hook that loads user state from localStorage on mount.

This hook is used by routed LiveViews to load the initial user state
from the browser's localStorage via connect params.

## Usage

Add to your routed LiveView:

    on_mount({Frameworks.UserState.LiveHook, __MODULE__})

The hook will:
1. Check if user_state is already assigned (skip if so)
2. Load user_state from connect params (sent by JavaScript)
3. Parse the flat localStorage format into nested structure
4. Assign to socket.assigns.user_state

# `on_mount`

# `optional_apply`

# `optional_apply`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
