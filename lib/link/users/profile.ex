defmodule Link.Users.Profile do
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
