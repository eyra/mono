# `mix config.snapshot`
[🔗](https://github.com/eyra/mono/blob/main/next/lib/mix/tasks/config.snapshot.ex#L1)

Evaluates `config/runtime.exs` with the environment variables of each
deployment (fixtures in `next/test/config/env/`) and compares the result
with the committed snapshots in `next/test/config/snapshots/`.

    mix config.snapshot            # fail when a snapshot differs
    mix config.snapshot --update   # rewrite the snapshots

The same check runs in `mix test` (`next/test/config/runtime_snapshot_test.exs`).
A changed snapshot, above all `prod`, is a change to what that environment
runs: review the diff before committing it.

# `fixtures`

# `render`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
