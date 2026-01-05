defmodule Systems.Assignment.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Assignment do
        pipe_through([:browser, :require_authenticated_user])
        live("/assignment/:id", CrewPage)
        live("/assignment/:id/content", ContentPage)
        live("/assignment/:id/landing", LandingPage)
        get("/assignment/:id/invite", Controller, :invite)
        get("/assignment/:id/apply", Controller, :apply)
        get("/assignment/:id/join", Controller, :join)
        get("/assignment/:id/export", Controller, :export)
        get("/assignment/callback/:workflow_item_id", Controller, :callback)
      end
    end
  end
end
