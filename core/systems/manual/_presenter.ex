defmodule Systems.Manual.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Manual

  @impl true
  def view_model(page, model, assigns) do
    builder(page).view_model(model, assigns)
  end

  defp builder(Manual.Builder.PublicPage), do: Manual.Builder.PublicPageBuilder
end
