defmodule Systems.NextAction.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.NextAction do
        pipe_through([:browser, :require_authenticated_user])
        live("/todo", OverviewPage)
      end
    end
  end
end
