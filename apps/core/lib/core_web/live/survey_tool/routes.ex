defmodule CoreWeb.Live.SurveyTool.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser, :require_authenticated_user])

        live("/survey-tools", SurveyTool.Index)
        live("/survey-tools/new", SurveyTool.New)
        live("/survey-tools/:id", SurveyTool.Edit)
      end
    end
  end
end
