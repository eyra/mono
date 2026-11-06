defmodule Next.Systems.Storybook.System do
  @moduledoc "The component storybook of Next's own components (`Next.Storybook`), next to Mica's Pixel storybook."
  use Mica.System

  def routes do
    quote do
      require PhoenixStorybook.Router

      scope "/" do
        pipe_through([:browser, MicaWeb.StorybookGuard])

        # Mica's Pixel storybook (`Systems.Admin.Routes`) defines the shared :storybook_browser
        # pipeline; the backend is an atom for the same reason as there.
        PhoenixStorybook.Router.live_storybook("/admin/storybook-next",
          backend_module: :"Elixir.Next.Storybook",
          session_name: :next_storybook,
          as: :next_storybook,
          pipeline: false
        )
      end
    end
  end
end
