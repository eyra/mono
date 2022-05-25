defmodule Systems.Pool.Switch do
  use Frameworks.Signal.Handler

  alias Core.Pools
  alias Frameworks.Signal

  alias Systems.{
    Pool
  }

  def dispatch(:criteria_updated, %{submission_id: submission_id} = _criteria) do
    submission = Pools.Submissions.get!(submission_id)
    Signal.Context.dispatch!(:submission_updated, submission)
  end

  def dispatch(:submission_updated, submission) do
    Pool.Presenter.update(Pool.OverviewPage)

    submission
    |> Pool.Presenter.update(submission.id, Pool.SubmissionPage)
  end
end
