defmodule Next.Systems.Graphite.Routes do
  defmacro routes() do
    quote do
      scope "/graphite", Next.Systems.Graphite do
        pipe_through([:browser, :require_authenticated_user])

        live("/leaderboard/:id/content", LeaderboardContentPage)
        live("/leaderboard/:id", LeaderboardPage)
        get("/:id", ToolController, :ensure_spot)
        get("/:id/export/submissions", ExportController, :submissions)
      end

      scope "/graphite", Next.Systems.Graphite do
        pipe_through([:browser])
        live("/:id/public/leaderboard", LeaderboardPage)
      end
    end
  end
end
