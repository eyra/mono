# `Mica.RuntimeConfig.Snapshot`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/runtime_config/snapshot.ex#L1)

Evaluates a runtime config file against a fixed set of environment variables
and renders the result as stable text, so a change in what an environment
gets shows up as a diff.

The process environment is replaced by the fixture for the duration of the
evaluation and restored afterwards, so callers must not run concurrently.

# `evaluate`

Evaluates `runtime_path` for `config_env` with exactly the variables in `env`.

The file is evaluated from a copy in a temporary directory, so paths relative
to it (such as a local `.env`) do not leak a developer's machine into the
result.

# `read_env_file`

Reads a fixture file with `NAME=value` lines. Blank lines and lines starting
with `#` are skipped; the value is everything after the first `=`.

# `render`

Renders an evaluated config as formatted, ordered Elixir terms.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
