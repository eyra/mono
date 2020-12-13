defmodule Link.Users.Profile do
  @moduledoc """
  This schema contains profile related data for members.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_profiles" do
    field :fullname, :string
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:fullname])
    |> validate_required([:fullname])
  end
end
