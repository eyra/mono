defmodule Systems.Pool.Switch do
  use Frameworks.Signal.Handler

  alias Frameworks.Signal
  alias Core.Authorization
  alias Core.Accounts.User
  alias Systems.Campaign
  alias Core.Repo
  import Ecto.Query

  alias Systems.{
    Pool
  }

  def dispatch(:criteria_updated, %{submission_id: submission_id} = _criteria) do
    submission = Pool.Context.get_submission!(submission_id)
    Signal.Context.dispatch!(:submission_updated, submission)
  end

  def dispatch(:submission_updated, submission) do
    Pool.Presenter.update(Pool.OverviewPage)

    submission
    |> Pool.Presenter.update(submission.id, Pool.SubmissionPage)
  end

  @impl true
  def dispatch(:campaign_created, %{campaign: campaign}) do
    from(u in User, where: u.coordinator == true)
    |> Repo.all()
    |> Enum.each(fn user ->
      Authorization.assign_role(user, campaign, :coordinator)
    end)
  end

  @impl true
  def dispatch(:user_profile_updated, %{user: user, user_changeset: user_changeset}) do
    if Map.has_key?(user_changeset.changes, :coordinator) do
      from(s in Campaign.Model)
      |> Repo.all()
      |> Enum.each(fn campaign ->
        if user_changeset.changes.coordinator do
          Authorization.assign_role(user, campaign, :coordinator)
        else
          Authorization.remove_role!(user, campaign, :coordinator)
        end
      end)
    end
  end
end
