defmodule SystemSignIn.User do
  use Ecto.Schema
  import Ecto.Changeset

  @fields ~w(name)a
  @required_fields @fields

  schema "system_users" do
    belongs_to(:user, Systems.Account.User)
    field(:name, :string)

    timestamps()
  end

  def changeset(%SystemSignIn.User{} = user, attrs) do
    user
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
