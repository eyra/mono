defmodule Systems.Zircon.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Zircon

  @impl true
  def view_model(Zircon.Screening.ImportView, model, assigns) do
    Zircon.Screening.ImportViewBuilder.view_model(model, assigns)
  end

  @impl true
  def view_model(Zircon.Screening.ImportSessionView, model, assigns) do
    Zircon.Screening.ImportSessionViewBuilder.view_model(model, assigns)
  end

  @impl true
  def view_model(Zircon.Screening.PaperSetView, model, assigns) do
    Zircon.Screening.PaperSetViewBuilder.view_model(model, assigns)
  end

  @impl true
  def view_model(Zircon.Screening.CriteriaView, model, assigns) do
    Zircon.Screening.CriteriaViewBuilder.view_model(model, assigns)
  end

  @impl true
  def view_model(Zircon.Screening.ImportSessionErrorsView, model, assigns) do
    Zircon.Screening.ImportSessionErrorsViewBuilder.view_model(model, assigns)
  end

  @impl true
  def view_model(Zircon.Screening.ImportSessionNewPapersView, model, assigns) do
    Zircon.Screening.ImportSessionNewPapersViewBuilder.view_model(model, assigns)
  end
end
