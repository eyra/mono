defmodule ExternalSignIn do
  alias Core.Accounts
  alias Core.Repo
  import Ecto.Query, warn: false

  def sign_in(conn, organisation, external_id) do
    user =
      if user = get_user_by_external_id(external_id) do
        user
      else
        register_user(organisation, external_id)
      end

    CoreWeb.UserAuth.log_in_user_without_redirect(conn, user)
  end

  def get_user_by_external_id(external_id) do
    external_user_query =
      from(ex in ExternalSignIn.User,
        where: ex.external_id == ^external_id,
        select: ex.user_id
      )

    from(u in Accounts.User, where: u.id in subquery(external_user_query))
    |> Repo.one()
  end

  def register_user(organisation, external_id) when is_atom(organisation) do
    register_user(Atom.to_string(organisation), external_id)
  end

  def register_user(organisation, external_id) do
    name = "#{organisation}_#{external_id}"

    user =
      Accounts.User.sso_changeset(%Accounts.User{}, %{
        email: "external_#{name}@eyra.co",
        researcher: false,
        student: false,
        displayname: name,
        profile: %{
          fullname: name
        }
      })

    external_user =
      ExternalSignIn.User.changeset(%ExternalSignIn.User{}, %{
        external_id: external_id,
        organisation: organisation
      })

    {:ok, result} =
      external_user
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Repo.insert()

    result.user
  end
end
