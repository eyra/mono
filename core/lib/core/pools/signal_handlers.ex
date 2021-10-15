defmodule Core.Pools.SignalHandlers do
  use Frameworks.Signal.Handler
  alias Core.Authorization
  alias Core.Accounts.User
  alias Core.Studies.Study
  alias Core.Repo
  import Ecto.Query

  @impl true
  def dispatch(:study_created, %{study: study}) do
    from(u in User, where: u.coordinator == true)
    |> Repo.all()
    |> Enum.each(fn user ->
      Authorization.assign_role(user, study, :coordinator)
    end)
  end

  @impl true
  def dispatch(:user_profile_updated, %{user: user, user_changeset: user_changeset}) do
    if Map.has_key?(user_changeset.changes, :coordinator) do
      from(s in Study)
      |> Repo.all()
      |> Enum.each(fn study ->
        if user_changeset.changes.coordinator do
          Authorization.assign_role(user, study, :coordinator)
        else
          Authorization.remove_role!(user, study, :coordinator)
        end
      end)
    end
  end
end
