defmodule Systems.Alliance.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Alliance

  @impl true
  def view_model(page, %Alliance.ToolModel{director: director} = tool, assigns) do
    Frameworks.Utility.Module.get(director, "Presenter").view_model(page, tool, assigns)
  end
end
