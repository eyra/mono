defmodule CoreWeb.Support.Endpoint do
  use Phoenix.Endpoint, otp_app: :core

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_link_key",
    signing_salt: "3oh1/4M5"
  ]

  @dependencies [
    path_provider: CoreWeb.Support.PathProvider
  ]

  socket("/socket", CoreWeb.UserSocket, websocket: true, longpoll: false)
  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :core,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

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
  plug(CoreWeb.Dependencies.Injector, @dependencies)
  plug(CoreWeb.Support.Router)
end
