defmodule Systems.Zircon.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Zircon

  @impl true
  def view_model(Zircon.Screening.CriteriaView, model, assigns) do
    Zircon.Screening.CriteriaViewBuilder.view_model(model, assigns)
  end
end
