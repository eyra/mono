defmodule Systems.Account.Switch do
  use Frameworks.Signal.Handler
  import Ecto.Changeset

  alias Systems.{
    NextAction,
    Email,
    Monitor
  }

  alias Systems.Account.NextActions.{CompleteProfile, PromotePushStudent}

  @impl true
  def intercept({:user_profile, :updated}, %{
        user: user,
        user_changeset: user_changeset,
        profile_changeset: profile_changeset
      }) do
    required_fields =
      if user.creator do
        [:fullname, :title]
      else
        [:fullname]
      end

    user_valid? = validate_required(user_changeset, [:displayname]).valid?
    profile_valid? = validate_required(profile_changeset, required_fields).valid?

    if user_valid? && profile_valid? do
      NextAction.Public.clear_next_action(user, CompleteProfile)
    else
      NextAction.Public.create_next_action(user, CompleteProfile)
    end

    :ok
  end

  @impl true
  def intercept(:visited_pages_updated, %{user: user, visited_pages: visited_pages}) do
    visited_settings? = Enum.member?(visited_pages, "settings")

    if visited_settings? do
      NextAction.Public.clear_next_action(user, PromotePushStudent)
    end

    :ok
  end

  @impl true
  def intercept(:features_updated, %{features: features, features_changeset: _changeset}) do
    Monitor.Public.log({features, :updated, features.user_id})
    :ok
  end

  @impl true
  def intercept({:user, :created}, %{user: user}) do
    Email.Factory.account_created(user)
    |> Email.Public.deliver_later()

    :ok
  end
end
