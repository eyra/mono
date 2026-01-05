defmodule Systems.Manual.Presenter do
  use Frameworks.Concept.Presenter

  alias Systems.Manual

  @impl true
  def view_model(Manual.Builder.PublicPage, model, assigns) do
    Manual.Builder.PublicPageBuilder.view_model(model, assigns)
  end

  def view_model(page, model, assigns) do
    builder(page).view_model(model, assigns)
  end
end
