defmodule Systems.Account.UserProfileEditModel do
  @moduledoc """
  The study type.
  """
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:user_id, :integer)
    field(:displayname, :string)
    field(:creator, :boolean)
    field(:fullname, :string)
    field(:title, :string)
    field(:photo_url, :string)
  end

  @required_fields ~w()a

  @user_fields ~w(displayname creator)a
  @profile_fields ~w(fullname title photo_url)a

  @fields @user_fields ++ @profile_fields

  def changeset(user_edit, _type, params) do
    user_edit
    |> cast(params, @fields)
    |> validate_required(@required_fields)
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

    struct(Systems.Account.UserProfileEditModel, opts)
  end
end
