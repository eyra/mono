# `Frameworks.UserState.Storage`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/user_state/storage.ex#L1)

Behaviour for user state storage backends.

Defines the contract for storing and retrieving user state key/value pairs.

# `save`

```elixir
@callback save(socket :: Phoenix.LiveView.Socket.t(), key :: String.t(), value :: any()) ::
  Phoenix.LiveView.Socket.t()
```

Saves a key/value pair to storage.

Returns the socket with any necessary side effects applied (e.g., push_event).

# `backend`

Returns the configured storage backend module.

# `save`

Saves a key/value pair using the configured storage backend.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
