defmodule Systems.Pool.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    Pool
  }

  @impl true
  def intercept(
        {:criteria, :updated} = signal,
        %{criteria: %{submission_id: submission_id}} = message
      ) do
    submission = Pool.Public.get_submission!(submission_id)
    dispatch!({:submission, signal}, Map.merge(message, %{submission: submission}))
    :ok
  end

  @impl true
  def intercept(
        {:submission, _} = signal,
        %{submission: submission, from_pid: from_pid} = message
      ) do
    update_page(Pool.SubmissionPage, submission, from_pid)
    pool = Pool.Public.get_by_submission!(submission)
    dispatch!({:pool, signal}, Map.merge(message, %{pool: pool}))
    :ok
  end

  @impl true
  def intercept({:pool, _}, %{pool: pool, from_pid: from_pid}) do
    update_page(Pool.DetailPage, pool, from_pid)
    :ok
  end

  defp update_page(page, %{id: id} = model, from_pid) do
    dispatch!({:page, page}, %{id: id, model: model, from_pid: from_pid})
  end
end
