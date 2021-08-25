defmodule CoreWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :core
  use SiteEncrypt.Phoenix

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_core_key",
    signing_salt: "3oh1/4M5"
  ]

  socket("/socket", CoreWeb.UserSocket,
    websocket: true,
    longpoll: false
  )

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [:user_agent, session: @session_options]]
  )

  bundle = Application.get_env(:core, :bundle)

  if bundle do
    plug(Plug.Static,
      at: "/",
      from: {:core, "priv/bundles/#{to_string(bundle)}"},
      gzip: false,
      only: ~w(css fonts images js favicon.ico robots.txt manifest.json sw.js)
    )
  end

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :core,
    gzip: false,
    only_matching: ~w(css fonts images js favicon apple-touch-icon robots manifest sw)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :core)
  end

  plug(Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(CoreWeb.Router)

  @impl Phoenix.Endpoint
  def init(_key, config) do
    {:ok, SiteEncrypt.Phoenix.configure_https(config)}
  end

  @impl SiteEncrypt
  def certification do
    SiteEncrypt.configure(Application.fetch_env!(:core, :ssl))
  end
end
