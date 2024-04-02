defmodule Systems.Graphite.Routes do
  defmacro routes() do
    quote do
      scope "/graphite", Systems.Graphite do
        pipe_through([:browser, :require_authenticated_user])

        live("/leaderboard/:leaderboard_id", LeaderboardPage)
        live("/:id/content", ContentPage)
        live("/:id/:spot", ToolPage)

        get("/:id", ToolController, :ensure_spot)
        get("/:id/export/submissions", ExportController, :submissions)
      end

      scope "/graphite", Systems.Graphite do
        pipe_through([:browser])
        live("/public/leaderboard/:leaderboard_id", LeaderboardPage)
        live("/:graphite_id/public/leaderboard", LeaderboardPage)
        live("/leaderboard/:leaderboard_id/content", Leaderboard.ContentPage)
      end
    end
  end
end
