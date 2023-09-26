defmodule Systems.Feldspar.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Feldspar
  }

  @impl true
  def view_model(%Feldspar.ToolModel{} = _tool, _page, _assigns) do
    %{}
  end
end
