defmodule Systems.Alliance.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Alliance

  @impl true
  def view_model(%Alliance.ToolModel{director: director} = tool, page, assigns) do
    Frameworks.Utility.Module.get(director, "Presenter").view_model(tool, page, assigns)
  end
end
