# `Mica.RuntimeConfig.Check`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/runtime_config/check.ex#L1)

Checks the runtime config of a release before it is started, without starting
the app or connecting to the database:

    bin/core eval "Mica.RuntimeConfig.Check.run()"

`bin/core eval` evaluates `config/runtime.exs` with the environment it is
given, so a missing or invalid variable that `runtime.exs` refuses already
fails there. This module then runs the checks the app would otherwise only hit
while starting: the endpoint secret, the database URL and CA file, and the
Oban, rate limiter and storage settings. Unknown Oban plugin names and
undeclared feature flags are warnings, as at start.

Output names settings and choices, never values.

# `check`

Checks `config`, a keyword list of applications and their config (as
`Config.Reader.read!/2` returns it). Returns `{:ok, warnings}` or
`{:error, problems, warnings}`.

# `run`

```elixir
@spec run() :: no_return()
```

Checks the loaded config, prints the result and halts: status 0 when the
config is valid, 1 when it is not.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
