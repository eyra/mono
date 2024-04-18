defmodule Systems.Graphite.Routes do
  defmacro routes() do
    quote do
      scope "/graphite", Systems.Graphite do
        pipe_through([:browser, :require_authenticated_user])

        live("/leaderboard/:id/content", LeaderboardContentPage)
        live("/leaderboard/:id/page", LeaderboardPage)
        get("/:id", ToolController, :ensure_spot)
        get("/:id/export/submissions", ExportController, :submissions)
      end

      scope "/graphite", Systems.Graphite do
        pipe_through([:browser])
        live("/leaderboard/:id", LeaderboardPage)
        live("/:id/public/leaderboard", LeaderboardPage)
      end
    end
  end
end
