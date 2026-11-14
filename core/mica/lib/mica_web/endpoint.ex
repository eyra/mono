defmodule MicaWeb.Endpoint do
  @moduledoc """
  Builds the endpoint of a SaaS. Each SaaS has its own:

      defmodule NextWeb.Endpoint do
        use MicaWeb.Endpoint, otp_app: :mica, router: MicaWeb.Router
      end

  Every SaaS gets the same endpoint: the user and LiveView sockets, the WWW
  redirect, the Content and Feldspar plugs, the static files of `otp_app`, the
  parsers with the Payment body reader and the session, and `router:` as the
  last plug. Its config is the SaaS's: `config :mica, NextWeb.Endpoint, ...`.

  Mica reaches the endpoint of the running SaaS through `Mica.SaaS.endpoint/0`.
  """

  # The same for every SaaS, so a session and a connected LiveView client
  # survive a change of endpoint module.
  @session_options [
    store: :cookie,
    key: "_core_key",
    signing_salt: "3oh1/4M5"
  ]

  @doc """
  The session options of every SaaS endpoint. The session is stored in the
  cookie and signed: its contents can be read but not tampered with.
  """
  def session_options, do: @session_options

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    router = Keyword.fetch!(opts, :router)

    quote do
      use Phoenix.Endpoint, otp_app: unquote(otp_app)

      require Mica.Env
      require Systems.Content.Plug
      require Systems.Feldspar.Plug

      @session_options MicaWeb.Endpoint.session_options()

      @doc false
      def __mica_endpoint__, do: true

      socket("/socket", Systems.Account.UserSocket,
        websocket: true,
        longpoll: false
      )

      plug(MicaWeb.WWWRedirect)

      socket("/live", Phoenix.LiveView.Socket,
        websocket: [connect_info: [:user_agent, session: @session_options]]
      )

      Systems.Content.Plug.setup()
      Systems.Feldspar.Plug.setup()

      # Serve at "/" the static files from "priv/static" directory.
      #
      # You should set gzip to true if you are running phx.digest
      # when deploying your static files in production.
      plug(Plug.Static,
        at: "/",
        from: unquote(otp_app),
        gzip: false,
        only_matching: MicaWeb.Path.statics()
      )

      # Code reloading can be explicitly enabled under the
      # :code_reloader configuration of your endpoint.
      if var!(code_reloading?) do
        socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
        plug(Phoenix.LiveReloader)
        plug(Phoenix.CodeReloader)
        plug(Phoenix.Ecto.CheckRepoStatus, otp_app: Mica.Env.app())
      end

      plug(Plug.RequestId)
      plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

      @http_body_max_size Mica.Env.compile_env([__MODULE__, :http_body_max_size], 210_000_000)

      plug(Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Phoenix.json_library(),
        body_reader: {Systems.Payment.Plug, :cache_body_reader, []},
        # Allow large uploads for data donation (configurable via HTTP_BODY_MAX_SIZE env var)
        length: @http_body_max_size
      )

      plug(Plug.MethodOverride)
      plug(Plug.Head)
      plug(Plug.Session, @session_options)
      plug(unquote(router))
    end
  end
end
