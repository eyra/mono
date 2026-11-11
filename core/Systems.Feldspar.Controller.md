# `Systems.Feldspar.Controller`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/feldspar/controller.ex#L1)

HTTP API endpoints for Feldspar client communication.

Provides endpoints for:
- Data donation uploads (large file handling via HTTP instead of WebSocket)
- Client-side logging (forwarded to AppSignal via Elixir Logger)

# `auth_module`

# `donate`

Accepts a data donation, stores it as a file, and schedules delivery.

Expects multipart/form-data with:
- key: Identifier key for the data
- context: JSON string containing assignment_id, task, group. The participant is
  taken from the user's own participation, not from the context.
- data: File upload containing the data

Returns:
- 200 with {status: "ok"} on success
- 400 if missing required fields (key, data, context), invalid context or assignment_id,
  a key that is not a string, a task or group that is not a string or integer, or a
  control character (CR, LF, NUL, ...) in any of them
- 401 if user not authenticated
- 403 if user is not a participant or tester of the assignment
- 422 if storage/delivery fails
- 429 if rate limited

# `log`

Accepts a log entry from the client and forwards it to Elixir Logger (-> AppSignal).

Expects JSON with:
- level: "debug" | "info" | "warn" | "error"
- message: string
- context: optional object with additional context (assignment_id, etc.)

Returns:
- 200 with {status: "ok"} on success
- 400 if missing required fields or invalid level
- 401 if user not authenticated
- 429 if rate limited

# `print_auth_roles`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
