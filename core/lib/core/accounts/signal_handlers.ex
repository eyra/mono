defmodule Core.Accounts.SignalHandlers do
  use Core.Signals.Handlers
  import Ecto.Changeset
  alias Core.Accounts
  alias Core.NextActions
  alias Core.Accounts.NextActions.{CompleteProfile, PromotePushStudent, SelectStudyStudent}
  alias Core.Accounts.Email

  @impl true
  def dispatch(:user_profile_updated, %{
        user: user,
        user_changeset: user_changeset,
        profile_changeset: profile_changeset
      }) do
    required_fields =
      case {user.researcher, user.student} do
        {_, true} -> [:fullname]
        _ -> [:fullname, :title, :url]
      end

    user_valid? = validate_required(user_changeset, [:displayname]).valid?
    profile_valid? = validate_required(profile_changeset, required_fields).valid?

    if user_valid? && profile_valid? do
      NextActions.clear_next_action(user, CompleteProfile)
    else
      NextActions.create_next_action(user, CompleteProfile)
    end
  end

  @impl true
  def dispatch(:features_updated, %{features: features, features_changeset: features_changeset}) do
    user = Accounts.get_user!(features.user_id)

    if user.student do
      validated =
        features_changeset
        |> validate_required([:study_program_codes])
        |> validate_length(:study_program_codes, min: 1)

      if validated.valid? do
        NextActions.clear_next_action(user, SelectStudyStudent)
      else
        NextActions.create_next_action(user, SelectStudyStudent)
      end
    end
  end

  @impl true
  def dispatch(:visited_pages_updated, %{
        user: user,
        user_changeset: %{changes: %{visited_pages: visited_pages}}
      }) do
    visited_settings? = Enum.member?(visited_pages, "settings")

    if user.student && visited_settings? do
      NextActions.clear_next_action(user, PromotePushStudent)
    end
  end

  @impl true
  def dispatch(:user_created, %{user: user}) do
    if user.student do
      NextActions.create_next_action(user, SelectStudyStudent)
      NextActions.create_next_action(user, PromotePushStudent)
    end

    Email.account_created(user)
    |> Core.Mailer.deliver_later()
  end
end
