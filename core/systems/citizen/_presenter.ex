defmodule Systems.Citizen.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Citizen,
    Pool
  }

  @impl true
  def view_model(%Pool.SubmissionModel{} = submission, Pool.SubmissionPage, assigns) do
    Citizen.Pool.SubmissionPageBuilder.view_model(submission, assigns)
  end

  @impl true
  def view_model(%Pool.Model{} = pool, Pool.DetailPage, assigns) do
    Citizen.Pool.DetailPageBuilder.view_model(pool, assigns)
  end
end
