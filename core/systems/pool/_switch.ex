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
    submission = Pool.Public.get_submission!(submission_id)
    Signal.Public.dispatch!(:submission_updated, submission)
  end

  def dispatch(:submission_updated, %{pool_id: pool_id} = submission) do
    Pool.Public.get!(pool_id)
    |> push_update(pool_id, Pool.DetailPage)

    submission
    |> push_update(submission.id, Pool.SubmissionPage)
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
        update_coordinator_role(campaign, user, user_changeset.changes.coordinator)
      end)
    end
  end

  defp update_coordinator_role(campaign, user, assign?) do
    if assign? do
      Authorization.assign_role(user, campaign, :coordinator)
    else
      Authorization.remove_role!(user, campaign, :coordinator)
    end
  end

  defp push_update(%Pool.Model{} = pool, id, page) do
    Signal.Public.dispatch!(%{page: page}, %{id: id, model: pool})
    pool
  end

  defp push_update(%Pool.SubmissionModel{} = submission, id, page) do
    Signal.Public.dispatch!(%{page: page}, %{id: id, model: submission})
    submission
  end
end
