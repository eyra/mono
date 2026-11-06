defmodule Next.Systems.Onyx.Presenter do
  @behaviour Frameworks.Concept.Presenter

  @impl true
  def view_model(Next.Systems.Onyx.LandingPage, model, assigns) do
    Next.Systems.Onyx.LandingPageBuilder.view_model(model, assigns)
  end
end
