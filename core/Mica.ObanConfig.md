# `Mica.ObanConfig`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/oban_config.ex#L1)

Builds the Oban config that `Mica.Application` starts, from `config :mica, Oban`,
the queues and crons the systems declare (`c:Mica.System.oban_queues/0`,
`c:Mica.System.oban_crons/0`) and the plugin names `config :mica, :oban_plugins`
enables.

Mica adds its own queues: `default` and this node's storage delivery queue.
The storage delivery queue is named after the node (`storage_delivery_local_core@host`):
data donation files wait on that node's disk, so only that node may run its jobs.

Plugins run only where their name is enabled (`ENABLED_OBAN_PLUGINS` in
releases, every name in `config/dev.exs`):

    config :mica, :oban_plugins,
      enabled: ["pruner", "lifeline", "advert_expiration"],
      schedule_overrides: [advert_expiration: "*/10 * * * *"]

A name is one of Mica's plugins (`plugins/0`) or a system's cron. All enabled
crons share one `Oban.Plugins.Cron`. `schedule_overrides` replaces the
schedule of the crons it names.

# `config`

`config` with Mica's queues and the `declared` queues. A queue that `config`
lists keeps the limit set there; `queues: false` (tests) keeps every queue off.
Raises when a system declares one of Mica's queues.

# `plugins`

Mica's own plugins, by name.

# `put_plugins`

`config` with the plugins and crons that `oban_plugins` (`config :mica,
:oban_plugins`) enables added to the plugins `config` lists, Mica's plugins
first, then one `Oban.Plugins.Cron` with the enabled `crons` in their order.
`plugins: false` (tests) keeps every plugin off. Raises when a system declares
a cron with the name of one of Mica's plugins.

# `queues`

Mica's own queues on `node`.

# `unknown_plugins`

The names `oban_plugins` enables that are neither Mica's plugins nor one of `crons`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
