defmodule Core.Accounts.UserProfileEdit do
  @moduledoc """
  The study type.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import EctoCommons.URLValidator

  embedded_schema do
    field(:user_id, :integer)
    field(:displayname, :string)
    field(:researcher, :boolean)
    field(:fullname, :string)
    field(:title, :string)
    field(:url, :string)
    field(:photo_url, :string)
  end

  @required_fields ~w(displayname)a

  @user_fields ~w(displayname researcher)a
  @profile_fields ~w(fullname title url photo_url)a

  @fields @user_fields ++ @profile_fields

  def changeset(user_edit, _type, params) do
    user_edit
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> validate_optional_url(:url)
  end

  def to_user(user_edit) do
    user_edit
    |> Map.take(@user_fields)
  end

  def to_profile(user_edit) do
    user_edit
    |> Map.take(@profile_fields)
  end

  def create(user, profile) do
    user_opts =
      user
      |> Map.take(@user_fields)
      |> Map.put(:user_id, user.id)

    profile_opts =
      profile
      |> Map.take(@profile_fields)

    opts =
      %{}
      |> Map.merge(user_opts)
      |> Map.merge(profile_opts)

    struct(Core.Accounts.UserProfileEdit, opts)
  end

  def validate_optional_url(changeset, field) do
    if blank?(changeset, field) do
      changeset
    else
      changeset |> validate_url(field)
    end
  end

  defp blank?(changeset, field) do
    %{changes: changes} = changeset
    value = Map.get(changes, field)
    blank?(value)
  end
end
