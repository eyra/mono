defmodule Systems.Pool.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Pool

  @impl true
  def view_model(page, %Pool.Model{} = pool, assigns) do
    builder(page).view_model(pool, assigns)
  end

  def builder(Pool.DetailPage), do: Pool.DetailPageBuilder
  def builder(Pool.LandingPage), do: Pool.LandingPageBuilder
  def builder(Pool.OverviewPage), do: Pool.OverviewPageBuilder
  def builder(Pool.ParticipantPage), do: Pool.ParticipantPageBuilder
  def builder(Pool.SubmissionPage), do: Pool.SubmissionPageBuilder
end
