defmodule Systems.Storage.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Storage do
        pipe_through([:browser, :require_authenticated_user])
        live("/storage/endpoint/:id/content", EndpointContentPage)
        get("/storage/endpoint/:id/export", Controller, :export)
        live("/storage/endpoint/:id/donation", DonationPage)
      end
    end
  end
end
