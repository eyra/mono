defmodule Systems.Lab.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Lab

  @impl true
  def view_model(page, model, assigns) do
    builder(page).view_model(model, assigns)
  end

  def builder(Lab.ContentPage), do: Lab.ContentPageBuilder
end
