defmodule Systems.Desktop.Presenter do
  @behaviour Frameworks.Concept.Presenter

  @impl true
  def view_model(Systems.Desktop.Page, user, assigns) do
    Systems.Desktop.PageBuilder.view_model(user, assigns)
  end
end
