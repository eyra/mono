defmodule Systems.BFF.System do
  @moduledoc """
  The backend for frontend (BFF) of the native apps: `GET /bff/page/:page`
  answers `{"blocks": [...]}` for a page of the mica-bff spec. Systems serve the
  pages through `c:Mica.System.bff_pages/0`; the blocks are the
  `Systems.BFF.Blocks.*` modules, generated at compile time by the mica_bff
  dependency. The app sends the spec version it implements in
  the `x-bff-spec` header, which is only recorded for now.
  """
  use Mica.System

  def routes do
    quote do
      # Like :native_signin: the app calls with the session cookie of its hidden WebView.
      pipeline :bff do
        plug(:accepts, ["json"])
        plug(:fetch_session)
        plug(MicaWeb.Plug.RemoteIp)
        plug(Systems.Account.Plug)

        plug(Cldr.Plug.PutLocale,
          apps: [cldr: MicaWeb.Cldr, gettext: :global, gettext: MicaWeb.Gettext],
          from: [:session, :accept_language],
          default: "en"
        )

        plug(:put_secure_browser_headers)
        plug(:fetch_current_user)
      end

      scope "/bff", Systems.BFF do
        pipe_through([:bff])
        get("/page/:page", PageController, :show)
      end
    end
  end
end
