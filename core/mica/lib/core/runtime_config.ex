defmodule Core.RuntimeConfig do
  @moduledoc """
  Building blocks for a SaaS's `config/runtime.exs`.

  Every helper takes the environment as a map (`System.get_env/0` in
  `runtime.exs`, a fixture in tests) and returns plain config values. They read
  each setting under one name only, and environment values choose the setup,
  never the platform the release runs on.
  """

  require Logger

  @doc "Returns the value of `name`, raising like `System.fetch_env!/1` when it is not set."
  def fetch!(env, name) do
    case Map.fetch(env, name) do
      {:ok, value} -> value
      :error -> raise System.EnvError, env: name
    end
  end

  @doc "Splits a comma-separated value into its trimmed, non-empty items."
  def list(nil), do: []

  def list(value) when is_binary(value) do
    value
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
  Repo options from `DATABASE_URL`.

  TLS is on when `DB_CA_PATH` is set. It verifies the peer unless
  `DB_TLS_VERIFY=verify_none`, and takes the server name for SNI and the
  hostname check from the URL host. `ECTO_IPV6=true` (or `1`) connects over IPv6.
  """
  def repo(env) do
    url = fetch!(env, "DATABASE_URL")

    [url: url]
    |> put_if(Map.has_key?(env, "DB_CA_PATH"), :ssl,
      cacertfile: env["DB_CA_PATH"],
      verify: tls_verify(env["DB_TLS_VERIFY"]),
      server_name_indication: url |> URI.parse() |> Map.fetch!(:host) |> to_charlist()
    )
    |> put_if(env["ECTO_IPV6"] in ~w(true 1), :socket_options, [:inet6])
  end

  defp tls_verify("verify_none"), do: :verify_none
  defp tls_verify(_), do: :verify_peer

  @doc """
  `:ex_aws` options: keys and region from the environment, plus an S3 endpoint
  when `AWS_ENDPOINT_URL_S3` is set (an S3-compatible store; the keys are then
  required and the region defaults to `auto`).
  """
  def s3(env) do
    case env["AWS_ENDPOINT_URL_S3"] do
      nil ->
        [
          access_key_id: env["AWS_ACCESS_KEY_ID"],
          secret_access_key: env["AWS_SECRET_ACCESS_KEY"],
          region: env["AWS_REGION"]
        ]

      endpoint ->
        uri = URI.parse(endpoint)

        [
          access_key_id: fetch!(env, "AWS_ACCESS_KEY_ID"),
          secret_access_key: fetch!(env, "AWS_SECRET_ACCESS_KEY"),
          region: Map.get(env, "AWS_REGION", "auto"),
          s3: [scheme: "#{uri.scheme}://", host: uri.host, port: uri.port || 443]
        ]
    end
  end

  @doc """
  Mailer options: Mailgun when `MAILGUN_API_KEY` is set, otherwise Amazon SES
  (with the keys and region from `s3/1`).

  Options: `:name` and `:domain` of the app, `:mail_domain` to send from and
  `:mailgun_base_uri`.
  """
  def mailer(env, opts) do
    name = Keyword.fetch!(opts, :name)
    noreply = "no-reply@#{Keyword.fetch!(opts, :mail_domain)}"

    case env["MAILGUN_API_KEY"] do
      nil ->
        [
          adapter: Bamboo.SesAdapter,
          domain: Keyword.fetch!(opts, :domain),
          default_from_email: {name, noreply}
        ]

      api_key ->
        [
          adapter: Bamboo.MailgunAdapter,
          base_uri: Keyword.fetch!(opts, :mailgun_base_uri),
          api_key: api_key,
          domain: Keyword.fetch!(opts, :mail_domain),
          default_from_email: "#{name} <#{noreply}>",
          hackney_opts: [recv_timeout: :timer.minutes(1)]
        ]
    end
  end

  @doc """
  Feature flags from `ENABLED_APP_FEATURES`. `:e2e` gates test-only endpoints
  and is never enabled when `deploy_env` is `:prod`.

  The list can only switch flags on (`Core.FeatureFlags`). Parsing is kept
  exactly as before, empty items included (they become the flag `:""`).
  """
  def features(env, deploy_env) do
    env
    |> Map.get("ENABLED_APP_FEATURES", "")
    |> String.split(~r"\s*,\s*")
    |> Enum.map(&String.to_atom/1)
    |> Enum.reject(&(&1 == :e2e and deploy_env == :prod))
    |> Enum.map(&{&1, true})
  end

  @max_links 40

  @doc """
  Whether `path` is `root` or lies inside it, after expanding both and
  resolving symbolic links in their existing parts.
  """
  def inside?(path, root) do
    path = real_path(path)
    Path.relative_to(path, real_path(root)) != path
  end

  defp real_path(path) do
    path
    |> Path.expand()
    |> Path.split()
    |> resolve(nil, 0)
  end

  defp resolve(_parts, _current, links) when links > @max_links,
    do: raise(ArgumentError, "too many symbolic links")

  defp resolve([], current, _links), do: current
  defp resolve([root | rest], nil, links), do: resolve(rest, root, links)

  defp resolve([part | rest], current, links) do
    candidate = Path.join(current, part)

    case File.read_link(candidate) do
      {:ok, target} -> resolve(Path.split(Path.expand(target, current)) ++ rest, nil, links + 1)
      {:error, _} -> resolve(rest, candidate, links)
    end
  end

  @doc "Erlang node names (`core@<host>`) for the hosts in `DIST_HOSTS`."
  def dist_hosts(env) do
    env["DIST_HOSTS"]
    |> list()
    |> Enum.map(&String.to_atom("core@#{&1}"))
  end

  @doc """
  Logs the setup the runtime config chose, never values: database TLS, mail
  adapter, S3 endpoint and cluster size. Warns about unknown Oban plugin names.
  """
  def log_choices do
    repo = Core.Env.get(Core.Repo, [])
    mailer = Core.Env.get(Systems.Email.Mailer, [])
    s3 = Application.get_env(:ex_aws, :s3, [])

    Logger.info(
      "Runtime config: " <>
        "db_tls=#{if repo[:ssl], do: "on", else: "off"} " <>
        "mail=#{inspect(mailer[:adapter])} " <>
        "s3_endpoint=#{if s3[:host], do: "custom", else: "default"} " <>
        "cluster_hosts=#{length(Core.Env.get(:dist_hosts, []))}"
    )

    case Core.ObanConfig.unknown_plugins(Core.SaaS.oban_crons(), Core.Env.get(:oban_plugins, [])) do
      [] ->
        :ok

      unknown ->
        Logger.warning(
          "ENABLED_OBAN_PLUGINS: unknown name(s) ignored: #{Enum.join(unknown, ", ")}"
        )
    end
  end

  defp put_if(opts, true, key, value), do: opts ++ [{key, value}]
  defp put_if(opts, false, _key, _value), do: opts
end
