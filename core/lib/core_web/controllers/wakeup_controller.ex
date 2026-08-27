defmodule CoreWeb.WakeupController do
  @moduledoc """
  Endpoint to wake up a suspended Fly Postgres database.

  Unlike the health check, this forces a fresh connection attempt
  outside the connection pool, which triggers Fly to wake up the DB.
  """
  use CoreWeb,
      {:controller, [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  def get(conn, _params) do
    conn = put_resp_header(conn, "content-type", "text/plain")

    # Get database config from repo
    config = Core.Repo.config()

    # Parse the DATABASE_URL or use config directly
    opts = [
      hostname: config[:hostname],
      port: config[:port] || 5432,
      username: config[:username],
      password: config[:password],
      database: config[:database],
      timeout: 30_000,
      connect_timeout: 30_000
    ]

    # Handle URL-based config (Fly.io uses DATABASE_URL)
    opts =
      case config[:url] do
        nil ->
          opts

        url ->
          uri = URI.parse(url)
          [username, password] = String.split(uri.userinfo || ":", ":")

          Keyword.merge(opts,
            hostname: uri.host,
            port: uri.port || 5432,
            username: username,
            password: password,
            database: String.trim_leading(uri.path || "/", "/")
          )
      end

    # Add socket options for IPv6 if configured
    opts =
      case config[:socket_options] do
        nil -> opts
        socket_opts -> Keyword.put(opts, :socket_options, socket_opts)
      end

    # Attempt a fresh connection outside the pool
    case Postgrex.start_link(opts) do
      {:ok, pid} ->
        # Connection successful - DB is awake
        Postgrex.query(pid, "SELECT 1", [])
        GenServer.stop(pid)
        resp(conn, 200, "ok")

      {:error, %Postgrex.Error{message: message}} ->
        resp(conn, 503, "db waking up: #{message}")

      {:error, error} ->
        resp(conn, 503, "db waking up: #{inspect(error)}")
    end
  end
end
