defmodule Systems.Document.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Document
  }

  @impl true
  def view_model(_page, %Document.ToolModel{} = _tool, _assigns) do
    %{}
  end
end
