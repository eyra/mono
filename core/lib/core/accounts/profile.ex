defmodule Core.Accounts.Profile do
  @moduledoc """
  This schema contains profile related data for members.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Accounts.User

  schema "user_profiles" do
    field(:fullname, :string)
    field(:title, :string)
    field(:url, :string)
    field(:photo_url, :string)
    belongs_to(:user, User)
    timestamps()
  end

  @required_fields ~w(fullname)a

  @fields ~w(fullname title url photo_url)a

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
