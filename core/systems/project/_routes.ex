defmodule Systems.Project.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Project do
        pipe_through([:browser, :require_authenticated_user])
        live("/projects/:id/content", ContentPage)
        live("/projects", OverviewPage)
      end
    end
  end
end
