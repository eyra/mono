defmodule Systems.Student.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Student,
    Pool
  }

  @impl true
  def view_model(%Pool.SubmissionModel{} = submission, Pool.SubmissionPage, assigns) do
    Student.Pool.SubmissionPageBuilder.view_model(submission, assigns)
  end

  @impl true
  def view_model(%Pool.Model{} = pool, Pool.DetailPage, assigns) do
    Student.Pool.DetailPageBuilder.view_model(pool, assigns)
  end
end
