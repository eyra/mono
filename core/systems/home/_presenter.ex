defmodule Systems.Home.Presenter do
  @behaviour Frameworks.Concept.Presenter

  @impl true
  def view_model(Systems.Home.Page, _, assigns) do
    Systems.Home.PageBuilder.view_model(nil, assigns)
  end
end
