defmodule Core.SurfConext.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "surfconext_users" do
    belongs_to(:user, Systems.Account.User)
    field(:email, :string)
    field(:sub, :string)
    field(:family_name, :string)
    field(:given_name, :string)
    field(:preferred_username, :string)
    field(:schac_home_organization, :string)
    field(:schac_personal_unique_code, {:array, :string})
    field(:eduperson_affiliation, {:array, :string})
    timestamps()
  end

  def register_changeset(%Core.SurfConext.User{} = user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :sub,
      :family_name,
      :given_name,
      :preferred_username,
      :schac_home_organization,
      :schac_personal_unique_code,
      :eduperson_affiliation
    ])
    |> validate_change(:schac_home_organization, fn :schac_home_organization, value ->
      limit_schac_home_organization = get_limit_schac_home_organization()

      if limit_schac_home_organization && value != limit_schac_home_organization do
        [schac_home_organization: "Your organization is not allowed to authenticate"]
      else
        []
      end
    end)
    |> validate_required([:email, :sub])
  end

  def update_changeset(%Core.SurfConext.User{} = user, attrs) do
    user
    |> cast(attrs, [:schac_personal_unique_code])
  end

  def get_limit_schac_home_organization do
    Application.get_env(:core, Core.SurfConext, [])
    |> Keyword.get(:limit_schac_home_organization)
  end
end
