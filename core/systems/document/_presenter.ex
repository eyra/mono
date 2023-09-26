defmodule Systems.Document.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Document
  }

  @impl true
  def view_model(%Document.ToolModel{} = _tool, _page, _assigns) do
    %{}
  end
end
