defmodule Mica.ObanConfig do
  @moduledoc """
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
  """

  alias Systems.Storage

  @doc "Mica's own queues on `node`."
  def queues(node \\ Node.self()) do
    [{Storage.Public.storage_delivery_queue(node), 1}, default: 5]
  end

  @doc "Mica's own plugins, by name."
  def plugins do
    [
      pruner: {Oban.Plugins.Pruner, max_age: 60 * 60},
      lifeline: {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(60)}
    ]
  end

  @doc """
  `config` with Mica's queues and the `declared` queues. A queue that `config`
  lists keeps the limit set there; `queues: false` (tests) keeps every queue off.
  Raises when a system declares one of Mica's queues.
  """
  def config(config, declared) do
    case Keyword.get(config, :queues, []) do
      false ->
        config

      configured ->
        Keyword.put(config, :queues, Keyword.merge(with_mica_queues(declared), configured))
    end
  end

  @doc """
  `config` with the plugins and crons that `oban_plugins` (`config :mica,
  :oban_plugins`) enables added to the plugins `config` lists, Mica's plugins
  first, then one `Oban.Plugins.Cron` with the enabled `crons` in their order.
  `plugins: false` (tests) keeps every plugin off. Raises when a system declares
  a cron with the name of one of Mica's plugins.
  """
  def put_plugins(config, crons, oban_plugins) do
    case Keyword.get(config, :plugins, []) do
      false ->
        config

      configured ->
        Keyword.put(config, :plugins, configured ++ enabled_plugins(crons, oban_plugins))
    end
  end

  @doc "The names `oban_plugins` enables that are neither Mica's plugins nor one of `crons`."
  def unknown_plugins(crons, oban_plugins) do
    case Keyword.get(oban_plugins, :enabled, []) do
      :all -> []
      enabled -> Enum.uniq(enabled -- names(crons))
    end
  end

  defp enabled_plugins(crons, oban_plugins) do
    enabled = Keyword.get(oban_plugins, :enabled, [])
    overrides = Keyword.get(oban_plugins, :schedule_overrides, [])

    plugins = for {name, plugin} <- plugins(), enabled?(name, enabled), do: plugin

    crontab =
      for {name, entry} <- without_mica_plugins(crons), enabled?(name, enabled) do
        case Keyword.fetch(overrides, name) do
          {:ok, schedule} -> put_elem(entry, 0, schedule)
          :error -> entry
        end
      end

    if crontab == [], do: plugins, else: plugins ++ [{Oban.Plugins.Cron, crontab: crontab}]
  end

  defp enabled?(_name, :all), do: true
  defp enabled?(name, enabled), do: Atom.to_string(name) in enabled

  defp names(crons), do: Enum.map(Keyword.keys(plugins()) ++ Keyword.keys(crons), &to_string/1)

  defp without_mica_plugins(crons) do
    case Enum.find(Keyword.keys(crons), &Keyword.has_key?(plugins(), &1)) do
      nil ->
        crons

      name ->
        raise ArgumentError, "Oban plugin #{inspect(name)} is Mica's; a system can't declare it"
    end
  end

  defp with_mica_queues(declared) do
    case Enum.filter(Keyword.keys(declared), &Keyword.has_key?(queues(), &1)) do
      [] ->
        queues() ++ declared

      [name | _] ->
        raise ArgumentError, "Oban queue #{inspect(name)} is Mica's; a system can't declare it"
    end
  end
end
