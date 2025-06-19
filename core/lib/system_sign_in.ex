defmodule SystemSignIn do
  alias Systems.Account
  alias Core.Repo
  import Ecto.Query, warn: false

  def setup_user(name) when is_atom(name) do
    setup_user(Atom.to_string(name))
  end

  def setup_user(name) when is_binary(name) do
    if user = get_user_by_name(name) do
      user
    else
      register_user(name)
    end
  end

  def sign_in(conn, name) do
    user = setup_user(name)

    conn
    |> Systems.Account.UserAuth.log_in_user_without_redirect(user)
    |> Plug.Conn.assign(:current_user, user)
  end

  def get_user_by_name(nil), do: nil

  def get_user_by_name(name) do
    from(u in Account.User,
      inner_join: su in SystemSignIn.User,
      on: su.user_id == u.id,
      where: su.name == ^name
    )
    |> Repo.one()
  end

  def register_user(name) when is_atom(name) do
    register_user(Atom.to_string(name))
  end

  def register_user(name) when is_binary(name) do
    user =
      Account.User.sso_changeset(%Account.User{}, %{
        email: "system+#{name}@eyra.co",
        creator: false,
        verified: false,
        displayname: String.capitalize(name),
        profile: %{
          fullname: "System #{String.capitalize(name)}"
        }
      })

    system_user =
      %SystemSignIn.User{}
      |> SystemSignIn.User.changeset(%{name: name})

    {:ok, result} =
      system_user
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Repo.insert()

    result.user
  end
end
