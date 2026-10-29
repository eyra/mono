defmodule Systems.Assignment.Routes do
  defmacro routes() do
    quote do
      pipeline :assignment_exists do
        plug(CoreWeb.ResourceExistsPlug, param: "id", fetch: {Systems.Assignment.Public, :get})
      end

      scope "/assignment/:id", Systems.Assignment do
        pipe_through([:browser, :require_authenticated_member, :assignment_exists])

        live("/", CrewPage)
        live("/landing", LandingPage)
      end

      scope "/assignment/:id", Systems.Assignment do
        pipe_through([:browser, :require_authenticated_user, :assignment_exists])

        live("/content", ContentPage)
        get("/export", Controller, :export_setup)
        get("/export-progress", Controller, :export_progress)
      end

      scope "/assignment/:id", Systems.Assignment do
        pipe_through([:browser, :require_authenticated_participant, :assignment_exists])

        get("/invite", Controller, :invite)
        get("/apply", Controller, :apply)
        get("/join", Controller, :join)
      end

      scope "/", Systems.Assignment do
        pipe_through([:browser, :require_authenticated_member])
        get("/assignment/callback/:workflow_item_id", Controller, :callback)
      end
    end
  end
end
