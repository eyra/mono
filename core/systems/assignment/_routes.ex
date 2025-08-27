defmodule Systems.Assignment.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Assignment do
        pipe_through([:browser, :require_authenticated_user])
        live("/assignment/:id", CrewPage)
        live("/assignment/:id/content", ContentPage)
        get("/assignment/:id/invite", Controller, :invite)
        get("/assignment/:id/apply", Controller, :apply)
        get("/assignment/:id/export", Controller, :export)
        get("/assignment/callback/:workflow_item_id", Controller, :callback)
      end

      scope "/assignment", Systems.Assignment do
        pipe_through([:browser, :validator])

        get("/:id/:entry", ExternalPanelController, :create,
          private: %{
            validate: %{
              id: &CoreWeb.Validator.Integer.valid_integer?/1,
              entry: &CoreWeb.Validator.String.valid_non_empty?/1
            },
            validation_handler:
              &Systems.Assignment.ExternalPanelController.validation_error_callback/2
          }
        )
      end
    end
  end
end
