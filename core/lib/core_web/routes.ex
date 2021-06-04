defmodule CoreWeb.Routes do
  defmacro routes() do
    quote do
      require CoreWeb.Live.Routes

      require CoreWeb.Cldr
      import CoreWeb.UserAuth

      pipeline :browser_base do
        plug(:accepts, ["html"])
        plug(:fetch_session)

        plug(Cldr.Plug.SetLocale,
          apps: [cldr: CoreWeb.Cldr, gettext: :global],
          from: [:query, :cookie, :accept_language],
          param: "locale"
        )

        plug(CoreWeb.Plug.LiveLocale)

        plug(:fetch_live_flash)
        plug(:put_root_layout, {CoreWeb.LayoutView, :root})
      end

      pipeline :browser_secure do
        # Documentation on the `put_secure_browser_headers` plug function
        # can be found here:
        # https://hexdocs.pm/phoenix/Phoenix.Controller.html#put_secure_browser_headers/2
        # Information about the content-security-policy can be found at:
        # https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
        plug(:put_secure_browser_headers)
        plug(:fetch_current_user)

        # Disabled CSP for now, Safari has issues with web-sockets and "self" (https://bugs.webkit.org/show_bug.cgi?id=201591)
        # , %{
        #   "content-security-policy" =>
        #     "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data:; font-src 'self' data:"
        # }
      end

      pipeline :browser do
        plug(:browser_base)
        plug(:protect_from_forgery)
        plug(:browser_secure)
      end

      pipeline :browser_unprotected do
        plug(:browser_base)
        plug(:browser_secure)
      end

      pipeline :api do
        plug(:accepts, ["json"])
      end

      CoreWeb.Live.Routes.routes()

      scope "/", CoreWeb do
        pipe_through(:api)

        post("/api/apns-token", APNSDeviceTokenController, :create)
      end
    end
  end
end
