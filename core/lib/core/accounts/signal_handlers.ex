defmodule Core.Accounts.SignalHandlers do
  use Core.Signals.Handlers
  import Ecto.Changeset
  alias Core.NextActions
  alias Core.Accounts.NextActions.CompleteProfile
  alias Core.Accounts.Email

  @impl true
  def dispatch(:user_profile_updated, %{user: user, profile_changeset: profile_changeset}) do
    valid? = validate_required(profile_changeset, [:fullname, :title]).valid?

    if valid? do
      NextActions.clear_next_action(user, CompleteProfile)
    else
      NextActions.create_next_action(user, CompleteProfile)
    end
  end

  @impl true
  def dispatch(:user_created, %{user: user}) do
    Email.account_created(user)
    |> Core.Mailer.deliver_later()
  end
end
