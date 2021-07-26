defmodule Core.Accounts.SignalHandlers do
  use Core.Signals.Handlers
  import Ecto.Changeset
  alias Core.NextActions
  alias Core.Accounts.NextActions.CompleteProfile

  @impl true
  def dispatch(:user_profile_updated, %{user: user, profile_changeset: profile_changeset}) do
    valid? = validate_required(profile_changeset, [:fullname, :title]).valid?

    if valid? do
      NextActions.clear_next_action(user, CompleteProfile)
    else
      NextActions.create_next_action(user, CompleteProfile)
    end
  end
end
