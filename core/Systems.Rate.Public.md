# `Systems.Rate.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/rate/_public.ex#L1)

# `auth_module`

# `counter`

The count of `key` in the current window of `window_seconds`, without
counting an event.

# `decrement_counter`

Takes back one event of `key` in the current window of `window_seconds`,
for an event `increment_counter/2` counted that didn't happen after all.
Never goes below 0.

# `delete_expired_counters`

Deletes the counters of windows that have ended. Returns the number of rows
deleted.

# `increment_counter`

Counts one event for `key` in the current fixed window of `window_seconds`
and returns the window's count, this event included.

Unlike the quotas of `request_permission/3`, which each node keeps in
memory, the counter is kept in the database: all nodes share it and it
survives restarts and deploys.

# `print_auth_roles`

# `request_permission`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
