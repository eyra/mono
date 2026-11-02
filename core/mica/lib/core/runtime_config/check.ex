defmodule Core.RuntimeConfig.Check do
  @moduledoc """
  Checks the runtime config of a release before it is started, without starting
  the app or connecting to the database:

      bin/core eval "Core.RuntimeConfig.Check.run()"

  `bin/core eval` evaluates `config/runtime.exs` with the environment it is
  given, so a missing or invalid variable that `runtime.exs` refuses already
  fails there. This module then runs the checks the app would otherwise only hit
  while starting: the endpoint secret, the database URL and CA file, and the
  Oban, rate limiter and storage settings. Unknown Oban plugin names and
  undeclared feature flags are warnings, as at start.

  Output names settings and choices, never values.
  """

  alias Systems.Rate
  alias Systems.Storage.BuiltIn

  @doc """
  Checks the loaded config, prints the result and halts: status 0 when the
  config is valid, 1 when it is not.
  """
  @spec run() :: no_return()
  def run do
    config = loaded_config()

    case check(config) do
      {:ok, warnings} ->
        Enum.each(warnings, &IO.puts("warning: #{&1}"))
        IO.puts("Runtime config check passed: #{summary(config)}")
        System.halt(0)

      {:error, problems, warnings} ->
        Enum.each(warnings, &IO.puts(:stderr, "warning: #{&1}"))
        IO.puts(:stderr, "Runtime config check failed:")
        Enum.each(problems, &IO.puts(:stderr, "  - #{&1}"))
        System.halt(1)
    end
  end

  @doc """
  Checks `config`, a keyword list of applications and their config (as
  `Config.Reader.read!/2` returns it). Returns `{:ok, warnings}` or
  `{:error, problems, warnings}`.
  """
  def check(config) do
    app = app_config(config)

    problems =
      Enum.flat_map([&endpoint/1, &repo/1, &oban/1, &rate/1, &upload_path/1], fn check ->
        try do
          check.(app)
        rescue
          e -> ["unexpected error in the config check: #{inspect(e.__struct__)}"]
        end
      end)

    case problems do
      [] -> {:ok, warnings(app)}
      problems -> {:error, problems, warnings(app)}
    end
  end

  defp endpoint(app) do
    case app[CoreWeb.Endpoint][:secret_key_base] do
      key when is_binary(key) and byte_size(key) >= 64 -> []
      key when is_binary(key) -> ["SECRET_KEY_BASE: must be at least 64 bytes"]
      _ -> ["SECRET_KEY_BASE: not set"]
    end
  end

  defp repo(app) do
    repo = app[Core.Repo] || []
    url_problems(repo[:url]) ++ ca_problems(repo[:ssl])
  end

  # Not the exception message: it would print the URL, password included.
  defp url_problems(url) when is_binary(url) and url != "" do
    Ecto.Repo.Supervisor.parse_url(url)
    []
  rescue
    _ -> ["DATABASE_URL: not a valid database URL"]
  end

  defp url_problems(_), do: ["DATABASE_URL: not set"]

  defp ca_problems(ssl) when is_list(ssl) do
    path = ssl[:cacertfile]

    if is_binary(path) and File.regular?(path),
      do: [],
      else: ["DB_CA_PATH: no file at #{inspect(path)}"]
  end

  defp ca_problems(_), do: []

  defp oban(app) do
    config = Core.Application.oban_config(app[Oban] || [], app[:oban_plugins] || [])

    case Oban.Config.validate(config) do
      :ok -> []
      {:error, message} -> ["Oban (ENABLED_OBAN_PLUGINS, FELDSPAR_CLEANUP_SCHEDULE): #{message}"]
    end
  end

  defp rate(app) do
    (app[:rate] || []) |> Core.Application.rate_config() |> Rate.Server.quotas()
    []
  rescue
    e -> ["RATE_QUOTAS: #{Exception.message(e)}"]
  end

  # The check `Systems.Storage.BuiltIn.Backend.check_upload_path!/0` runs at start.
  defp upload_path(app) do
    if app[BuiltIn][:special] == BuiltIn.LocalFS do
      BuiltIn.LocalFS.check_upload_path!(app[:upload_path], app[BuiltIn.LocalFS][:root_path])
    end

    []
  rescue
    e in RuntimeError -> ["UPLOAD_PATH: #{e.message}"]
  end

  defp warnings(app) do
    oban_plugins = app[:oban_plugins] || []

    unknown_plugins =
      case Core.ObanConfig.unknown_plugins(Core.SaaS.oban_crons(), oban_plugins) do
        [] -> []
        names -> ["ENABLED_OBAN_PLUGINS: unknown name(s) ignored: #{Enum.join(names, ", ")}"]
      end

    undeclared_features =
      for name <- Core.FeatureFlags.undeclared(app[:features] || []) do
        "ENABLED_APP_FEATURES: #{inspect(name)} is configured, but no system declares it"
      end

    unknown_plugins ++ undeclared_features
  end

  defp summary(config) do
    app = app_config(config)
    s3 = config[:ex_aws][:s3] || []

    "db_tls=#{if app[Core.Repo][:ssl], do: "on", else: "off"} " <>
      "mail=#{inspect(app[Systems.Email.Mailer][:adapter])} " <>
      "s3_endpoint=#{if s3[:host], do: "custom", else: "default"} " <>
      "storage=#{inspect(app[BuiltIn][:special])} " <>
      "cluster_hosts=#{length(app[:dist_hosts] || [])}"
  end

  defp app_config(config), do: config[Core.Env.app()] || []

  # `bin/core eval` boots without loading the applications, and their config
  # is only readable once they are.
  defp loaded_config do
    app = Core.Env.app()
    Application.load(app)
    Enum.each(Application.spec(app, :applications) || [], &Application.load/1)

    for name <- [app, :ex_aws], do: {name, Application.get_all_env(name)}
  end
end
