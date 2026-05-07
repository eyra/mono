defmodule Systems.Document.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Document

  @impl true
  def view_model(_page, %Document.ToolModel{} = tool, assigns) do
    Document.ToolViewBuilder.view_model(tool, assigns)
  end
end
