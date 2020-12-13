defmodule Link.Users.Profile do
  @moduledoc """
  This schema contains profile related data for members.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Link.Users.User

  schema "user_profiles" do
    field :fullname, :string
    field :researcher, :boolean
    belongs_to :user, User
    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:fullname, :researcher])
    |> validate_required([:fullname])
  end
end
