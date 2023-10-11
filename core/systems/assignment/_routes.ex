defmodule Systems.Assignment.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Assignment do
        pipe_through([:browser, :require_authenticated_user])
        live("/assignment/:id", CrewPage)
        live("/assignment/:id/landing", LandingPage)
        live("/assignment/:id/content", ContentPage)
        get("/assignment/callback/:item", Controller, :callback)
      end
    end
  end
end
