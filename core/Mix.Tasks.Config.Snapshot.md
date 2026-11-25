# `mix config.snapshot`
[🔗](https://github.com/eyra/mono/blob/main/next/lib/mix/tasks/config.snapshot.ex#L1)

Evaluates `config/runtime.exs` with the environment variables of each
deployment (fixtures in `next/test/config/env/`) and compares the result
with the committed snapshots in `next/test/config/snapshots/`.

    BUNDLE=next mix config.snapshot            # fail when a snapshot differs
    BUNDLE=next mix config.snapshot --update   # rewrite the snapshots

It runs in the test env, which configures a SaaS only through BUNDLE. The
snapshots are of Next's config, so it refuses to run without BUNDLE=next.

The same check runs in `mix test` (`next/test/config/runtime_snapshot_test.exs`).
A changed snapshot, above all `prod`, is a change to what that environment
runs: review the diff before committing it.

# `check_saas!`

Refuses a build that is not Next's: without Next's config (`next/config/config.exs`,
which only BUNDLE=next imports in the test env) the snapshots come out wrong.

# `fixtures`

# `render`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
