defmodule Systems.Lab.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Lab
  }

  @impl true
  def view_model(%Lab.ToolModel{} = _tool, _page, _assigns) do
    %{}
  end
end
