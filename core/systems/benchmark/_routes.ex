defmodule Systems.Benchmark.Routes do
  defmacro routes() do
    quote do
      scope "/benchmark", Systems.Benchmark do
        pipe_through([:browser, :require_authenticated_user])

        live("/:id/content", ContentPage)
        live("/:id/:spot", ToolPage)

        get("/:id", ToolController, :ensure_spot)
        get("/:id/export/submissions", ExportController, :submissions)
      end

      scope "/benchmark", Systems.Benchmark do
        pipe_through([:browser])
        live("/:id/public/leaderboard", LeaderboardPage)
      end
    end
  end
end
