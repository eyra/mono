defmodule Systems.Support.Presenter do
  use Frameworks.Concept.Presenter

  @impl true
  def view_model(page, model, assigns) do
    builder(page).view_model(model, assigns)
  end
end
