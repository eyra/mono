defmodule Systems.Project.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Project do
        pipe_through([:browser, :require_authenticated_user])
        live("/project", OverviewPage)
        live("/project/node/:id", NodePage)
        live("/project/item/:id/content", ItemContentPage)
      end
    end
  end
end
