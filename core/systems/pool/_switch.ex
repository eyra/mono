defmodule Systems.Pool.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    Pool
  }

  @impl true
  def intercept({:criteria, :updated} = signal, %{submission_id: submission_id} = _criteria) do
    dispatch!({:submission, signal}, Pool.Public.get_submission!(submission_id))
  end

  @impl true
  def intercept({:submission, _} = signal, submission) do
    update_page(Pool.SubmissionPage, submission)
    dispatch!({:pool, signal}, Pool.Public.get_by_submission!(submission))
  end

  @impl true
  def intercept({:pool, _}, pool) do
    update_page(Pool.DetailPage, pool)
  end

  defp update_page(page, %{id: id} = model) do
    dispatch!({:page, page}, %{id: id, model: model})
  end
end
