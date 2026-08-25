defmodule Systems.Account.Identity.Surfconext.UserModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "surfconext_users" do
    belongs_to(:user, Systems.Account.User)
    field(:email, :string)
    field(:sub, :string)
    field(:userinfo, :map, default: %{})
    timestamps()
  end

  def register_changeset(%Systems.Account.Identity.Surfconext.UserModel{} = user, attrs) do
    user
    |> cast(attrs, [:email, :sub, :userinfo])
    |> validate_required([:email, :sub])
  end

  def update_changeset(%Systems.Account.Identity.Surfconext.UserModel{} = user, attrs) do
    cast(user, attrs, [:userinfo])
  end
end
