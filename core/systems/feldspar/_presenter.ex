defmodule Systems.Feldspar.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Feldspar
  }

  @impl true
  def view_model(_page, %Feldspar.ToolModel{} = _tool, _assigns) do
    %{}
  end
end
