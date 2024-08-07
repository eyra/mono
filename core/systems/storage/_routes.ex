defmodule Systems.Storage.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Storage do
        pipe_through([:browser, :require_authenticated_user])
        live("/storage/:id/content", EndpointContentPage)
        get("/storage/:id/export", Controller, :export)
      end
    end
  end
end
