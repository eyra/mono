defmodule Systems.Admin.Routes do
  defmacro routes() do
    quote do
      scope "/admin", Systems.Admin do
        pipe_through([:browser])

        live("/login", LoginPage)
        live("/config", ConfigPage)
      end

      # Assets get the guard too, so nothing of the storybook is served where it is off (prod).
      scope "/" do
        pipe_through([:browser_unprotected, MicaWeb.StorybookGuard])
        PhoenixStorybook.Router.storybook_assets()
      end

      scope "/" do
        pipe_through([:browser, MicaWeb.StorybookGuard])

        # An atom, not an alias: an alias makes the router (and every file compile-connected to
        # it) recompile whenever a story is added or removed. Defines the :storybook_browser
        # pipeline that Next's storybook shares.
        PhoenixStorybook.Router.live_storybook("/admin/storybook",
          backend_module: :"Elixir.MicaWeb.Storybook"
        )
      end
    end
  end
end
