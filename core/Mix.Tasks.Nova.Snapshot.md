# `mix nova.snapshot`
[🔗](https://github.com/eyra/mono/blob/main/next/lib/mix/tasks/nova.snapshot.ex#L1)

Captures what a SaaS build wires together, so that the Nova migration
(plan step code-systems) can move routes, grants, handlers and SaaS config
between modules and show that nothing changed. The snapshots per SaaS are
committed in `next/test/snapshots/<saas>/`:

  * `routes.exs`: every route as `{verb, path, plug, plug_opts, helper, module}`,
    in router order
  * `permissions.exs`: `Mica.Authorization.permission_map/0`
  * `signal.exs`: signal handlers (in order), notifiers and notify channels
  * `flags.exs`: the effective feature flags at compile time
  * `saas_config.exs`: the `Mica.SaaS` callbacks (start pages, menus, title,
    signed-in pages), the SaaS app config and account and admin tab order
  * `runtime.exs`: the children `Mica.Application` starts, and per env fixture
    of `mix config.snapshot` the Oban queues and plugins (crontab sorted), the
    unknown names in `ENABLED_OBAN_PLUGINS`, the rate quotas and the effective
    feature flags
  * `counts.exs`: boundary allowlist size, `no route path` compile warnings and
    the files `MicaWeb.Router` is compile-connected to

Config-derived snapshots read `config/config.exs` as a prod build would
(`Config.Reader`, env `:prod`). `runtime.exs` adds `config/runtime.exs` for each
env fixture; the rest of the runtime config and the runtime flag list are
covered by `mix config.snapshot`, not here. The node-local storage queue is
rendered as `storage_delivery_local_<node>`.

    mix nova.snapshot                              # Next: fail on drift
    BUNDLE=self MIX_ENV=dev mix nova.snapshot      # Self: fail on drift
    mix nova.snapshot --update                     # rewrite the snapshots

Self needs `MIX_ENV=dev`: `config/test.exs` pins `:saas` to `Next.SaaS`.

Routes pass when the route set is identical and every two routes that can
match the same request keep their relative order; other reordering is allowed.
Everything else must be identical. Next is also checked in `mix test`
(`next/test/snapshots/nova_snapshot_test.exs`), Self in the `snapshot-self` CI job.

# `compare`

Compares one rendered snapshot with its committed file.

# `overlap?`

Whether two routes can match the same request.

# `path`

# `render`

Renders the snapshots of the current build as `{file name, text}`. `counts: false`
leaves out `counts.exs`, which runs `mix compile` and `mix xref` in a subprocess.

# `saas!`

The SaaS the current build is for. Raises when config and `BUNDLE` disagree.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
