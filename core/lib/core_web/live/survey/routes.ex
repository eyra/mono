defmodule CoreWeb.Live.Survey.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser, :require_authenticated_user])

        live("/survey-tools", Tool.Index)
        live("/survey-tools/new", Tool.New)
        live("/survey-tools/:id", Tool.Edit)
      end
    end
  end
end
