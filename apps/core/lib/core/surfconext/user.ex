defmodule Core.SurfConext.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "surfconext_users" do
    belongs_to(:user, Core.Accounts.User)
    field(:email, :string)
    field(:sub, :string)
    field(:family_name, :string)
    field(:given_name, :string)
    field(:preferred_username, :string)
    field(:schac_home_organization, :string)

    timestamps()
  end

  def changeset(%Core.SurfConext.User{} = user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :sub,
      :family_name,
      :given_name,
      :preferred_username,
      :schac_home_organization
    ])
    |> validate_required(:sub)
  end
end
