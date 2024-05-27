defmodule Systems.Assignment.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Assignment do
        pipe_through([:browser, :require_authenticated_user])
        live("/assignment/:id", CrewPage)
        live("/assignment/:id/landing", LandingPage)
        live("/assignment/:id/content", ContentPage)
        get("/assignment/:id/invite", Controller, :invite)
        get("/assignment/:id/apply", Controller, :apply)
        get("/assignment/callback/:item", Controller, :callback)
      end

      scope "/assignment", Systems.Assignment.Centerdata do
        pipe_through([:browser])
        live("/centerdata/fakeapi/page", Centerdata.FakeApiPage)
      end

      scope "/assignment", Systems.Assignment do
        pipe_through([:browser])
        get("/:id/:entry", ExternalPanelController, :create)
      end

      scope "/assignment", Systems.Assignment do
        pipe_through([:browser_unprotected])
        post("/:id/:entry", ExternalPanelController, :create)
      end
    end
  end
end
