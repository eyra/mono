defmodule Link.Accounts.Profile do
  @moduledoc """
  This schema contains profile related data for members.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Link.Accounts.User

  schema "user_profiles" do
    field :fullname, :string
    belongs_to :user, User
    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:fullname])
    |> validate_required([:fullname])
  end
end
