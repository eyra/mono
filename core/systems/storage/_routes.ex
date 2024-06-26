defmodule Systems.Storage.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Storage do
        pipe_through([:browser, :require_authenticated_user])
        live("/storage/:id/content", EndpointContentPage)
      end
    end
  end
end
