defmodule Systems.Feldspar.Presenter do
  use Frameworks.Concept.Presenter

  alias Systems.Feldspar

  @impl true
  def view_model(Feldspar.ToolView, %Feldspar.ToolModel{} = tool, assigns) do
    builder(Feldspar.ToolView).view_model(tool, assigns)
  end
end
