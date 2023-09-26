defmodule Systems.Assignment.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Assignment do
        pipe_through([:browser, :require_authenticated_user])
        live("/assignment/:id", LandingPage)
        live("/assignment/:id/content", ContentPage)
      end

      scope "/", Frameworks.Utility do
        pipe_through([:browser, :require_authenticated_user])
        get("/task/:type/:id/callback", LegacyRoutesController, :task_callback)
      end
    end
  end
end
