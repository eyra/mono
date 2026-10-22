defmodule Systems.Student.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Student,
    Pool
  }

  @impl true
  def view_model(Pool.SubmissionPage, %Pool.SubmissionModel{} = submission, assigns) do
    Student.Pool.SubmissionPageBuilder.view_model(submission, assigns)
  end

  @impl true
  def view_model(Pool.DetailPage, %Pool.Model{} = pool, assigns) do
    Student.Pool.DetailPageBuilder.view_model(pool, assigns)
  end
end
