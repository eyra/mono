defmodule Systems.Assignment.Routes do
  defmacro routes() do
    quote do
      pipeline :assignment_exists do
        plug(CoreWeb.ResourceExistsPlug, param: "id", fetch: {Systems.Assignment.Public, :get})
      end

      scope "/assignment/:id", Systems.Assignment do
        pipe_through([:browser, :require_authenticated_user, :assignment_exists])

        live("/", CrewPage)
        live("/content", ContentPage)
        live("/landing", LandingPage)
        get("/invite", Controller, :invite)
        get("/apply", Controller, :apply)
        get("/join", Controller, :join)
        get("/export", Controller, :export)
      end

      scope "/", Systems.Assignment do
        pipe_through([:browser, :require_authenticated_user])
        get("/assignment/callback/:workflow_item_id", Controller, :callback)
      end
    end
  end
end
