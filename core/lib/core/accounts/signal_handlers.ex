defmodule Core.Accounts.SignalHandlers do
  use Frameworks.Signal.Handler
  import Ecto.Changeset
  alias Core.Accounts

  alias Systems.{
    NextAction,
    Email
  }

  alias Core.Accounts.NextActions.{CompleteProfile, PromotePushStudent, SelectStudyStudent}

  @impl true
  def intercept({:user_profile, :updated}, %{
        user: user,
        user_changeset: user_changeset,
        profile_changeset: profile_changeset
      }) do
    required_fields =
      case {user.researcher, user.student} do
        {true, _} -> [:fullname, :title]
        {_, true} -> [:fullname]
        _ -> [:fullname]
      end

    user_valid? = validate_required(user_changeset, [:displayname]).valid?
    profile_valid? = validate_required(profile_changeset, required_fields).valid?

    if user_valid? && profile_valid? do
      NextAction.Public.clear_next_action(user, CompleteProfile)
    else
      NextAction.Public.create_next_action(user, CompleteProfile)
    end
  end

  @impl true
  def intercept(:features_updated, %{features: features, features_changeset: features_changeset}) do
    user = Accounts.get_user!(features.user_id)

    if user.student do
      validated =
        features_changeset
        |> validate_required([:study_program_codes])
        |> validate_length(:study_program_codes, min: 1)

      if validated.valid? do
        NextAction.Public.clear_next_action(user, SelectStudyStudent)
      else
        NextAction.Public.create_next_action(user, SelectStudyStudent)
      end
    end
  end

  @impl true
  def intercept(:visited_pages_updated, %{user: user, visited_pages: visited_pages}) do
    visited_settings? = Enum.member?(visited_pages, "settings")

    if visited_settings? do
      NextAction.Public.clear_next_action(user, PromotePushStudent)
    end
  end

  @impl true
  def intercept({:user, :created}, %{user: user}) do
    if user.student do
      NextAction.Public.create_next_action(user, SelectStudyStudent)
      NextAction.Public.create_next_action(user, PromotePushStudent)
    end

    Email.Factory.account_created(user)
    |> Email.Public.deliver_later()
  end
end
