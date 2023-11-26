defmodule Systems.Lab.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Lab
  }

  @impl true
  def view_model(_page, %Lab.ToolModel{} = _tool, _assigns) do
    %{}
  end
end
