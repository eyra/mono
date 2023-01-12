defmodule Systems.Scholar.Routes do
  defmacro routes() do
    quote do
      scope "/scholar", Systems.Scholar do
        pipe_through([:browser, :require_authenticated_user])
        get("/export/credits", ExportController, :credits)
      end
    end
  end
end
