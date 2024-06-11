defmodule Systems.Home.Presenter do
  @behaviour Frameworks.Concept.Presenter

  @impl true
  def view_model(Systems.Home.Page, user, assigns) do
    Systems.Home.PageBuilder.view_model(user, assigns)
  end
end
