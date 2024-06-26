defmodule ExternalSignIn do
  alias Systems.Account
  alias Core.Repo
  import Ecto.Query, warn: false

  def sign_in(conn, organisation, external_id) do
    user =
      if user = get_user_by_external_id(external_id) do
        user
      else
        register_user(organisation, external_id)
      end

    conn
    |> Systems.Account.UserAuth.log_in_user_without_redirect(user)
    |> Plug.Conn.assign(:current_user, user)
  end

  def get_user_by_external_id(nil), do: nil

  def get_user_by_external_id(external_id) do
    external_user_query =
      from(ex in ExternalSignIn.User,
        where: ex.external_id == ^external_id,
        select: ex.user_id
      )

    from(u in Account.User, where: u.id in subquery(external_user_query))
    |> Repo.one()
  end

  def register_user(organisation, external_id) when is_atom(organisation) do
    register_user(Atom.to_string(organisation), external_id)
  end

  def register_user(organisation, external_id) do
    name = "#{organisation}_#{external_id}"

    user =
      Account.User.sso_changeset(%Account.User{}, %{
        email: "external+#{name}@eyra.co",
        creator: false,
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
