defmodule Systems.Graphite.Routes do
  defmacro routes() do
    quote do
      scope "/graphite", Systems.Graphite do
        pipe_through([:browser, :require_authenticated_user])

        live("/leaderboard/:id/content", LeaderboardContentPage)

        live("/:id/content", ContentPage)
        live("/:id/:spot", ToolPage)

        get("/:id", ToolController, :ensure_spot)
        get("/:id/export/submissions", ExportController, :submissions)
      end

      scope "/graphite", Systems.Graphite do
        pipe_through([:browser])
        live("/:id/public/leaderboard", LeaderboardPage)
      end
    end
  end
end
