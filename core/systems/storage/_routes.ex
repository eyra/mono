defmodule Systems.Storage.Routes do
  @moduledoc false
  defmacro routes() do
    quote do
      scope "/", Systems.Storage do
        pipe_through([:browser, :require_authenticated_user])
        live("/storage/endpoint/:id/content", EndpointContentPage)
        get("/storage/endpoint/:id/export", Controller, :export)
      end
    end
  end
end
