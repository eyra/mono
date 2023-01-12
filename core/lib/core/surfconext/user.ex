defmodule Core.SurfConext.User do
  use Ecto.Schema
  import Ecto.Changeset

  # urn:schac:personalUniqueCode:nl:<scope>:<organisation_id>:<id_type>:<id_token>
  @personal_unique_code_regex Regex.compile!(
                                "^urn:schac:personalUniqueCode:nl:([^:]*):([^:]*):([^:]*):(.*)"
                              )

  schema "surfconext_users" do
    belongs_to(:user, Core.Accounts.User)
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

  def student_id(%Core.SurfConext.User{schac_personal_unique_code: codes}) when is_list(codes) do
    codes
    |> Enum.flat_map(fn code ->
      case Regex.run(@personal_unique_code_regex, code) do
        [_, _scope, _organisation_id, "studentid", student_id] -> [student_id]
        _ -> []
      end
    end)
  end

  def student_id(_), do: nil
end
