defmodule MicaWeb.Pipelines do
  @moduledoc """
  The pipelines Mica's routes `pipe_through`, for a SaaS router:

      defmodule NextWeb.Router do
        use NextWeb, :router
        require MicaWeb.Pipelines

        MicaWeb.Pipelines.define()
        ...
      end

  Their names are part of the contract between Mica's systems and every SaaS
  router: `:browser_base`, `:browser_secure`, `:browser`, `:browser_unprotected`,
  `:api` and `:validator`. The router also gets the function plugs routes pipe
  through, such as `:require_authenticated_user` (`Systems.Account.UserAuth`).
  """

  defmacro define do
    quote do
      require MicaWeb.Cldr
      import Systems.Account.UserAuth
      import MicaWeb.Meta

      alias MicaWeb.Validator.Plug, as: Validator

      pipeline :browser_base do
        plug(:accepts, ["html"])
        plug(:fetch_session)

        plug(Systems.Account.Plug)

        plug(MicaWeb.Plug.ResolveLocale)

        plug(Cldr.Plug.PutLocale,
          apps: [
            cldr: MicaWeb.Cldr,
            gettext: :global,
            gettext: MicaWeb.Gettext,
            gettext: Timex.Gettext
          ],
          from: [:session, :accept_language],
          default: "en"
        )

        plug(MicaWeb.Plug.PersistLocale)

        plug(MicaWeb.Plug.RemoteIp)

        plug(:fetch_live_flash)
        plug(:fetch_meta_info)
        plug(:put_root_layout, {MicaWeb.Layouts, :root})
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
        plug(:fetch_session)
        plug(:fetch_current_user)
        plug(:fetch_live_flash)
      end

      pipeline :validator do
        plug(Validator)
      end
    end
  end
end
