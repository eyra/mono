defmodule Systems.Account.Auth.Centerdata.UserModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "centerdata_user" do
    belongs_to(:user, Systems.Account.User)
    field(:email, :string)
    field(:sub, :string)
    field(:userinfo, :map, default: %{})
    timestamps()
  end

  def changeset(%__MODULE__{} = identity, userinfo) do
    identity
    |> cast(%{email: userinfo["email"], sub: userinfo["sub"], userinfo: userinfo}, [
      :email,
      :sub,
      :userinfo
    ])
    |> validate_required([:email, :sub])
  end
end
