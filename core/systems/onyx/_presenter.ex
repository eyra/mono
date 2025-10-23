defmodule Systems.Onyx.Presenter do
  @behaviour Frameworks.Concept.Presenter

  @impl true
  def view_model(Systems.Onyx.LandingPage, model, assigns) do
    Systems.Onyx.LandingPageBuilder.view_model(model, assigns)
  end
end
