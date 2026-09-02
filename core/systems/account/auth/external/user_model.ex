defmodule Systems.Account.Auth.External.UserModel do
  use Ecto.Schema
  import Ecto.Changeset

  @fields ~w(external_id organisation)a
  @required_fields @fields

  schema "external_users" do
    belongs_to(:user, Systems.Account.User)
    field(:external_id, :string)
    field(:organisation, :string)

    timestamps()
  end

  def changeset(%Systems.Account.Auth.External.UserModel{} = user, attrs) do
    user
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
