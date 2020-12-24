defmodule LinkWeb.Studies.PermissionsController do
  use LinkWeb, :controller
  alias Link.{Studies, Users}

  entity_loader(&LinkWeb.Loaders.study!/3, is_nested: true)

  def show(%{assigns: %{study: study}} = conn, _params) do
    owners = Studies.list_owners(study)
    render(conn, "show.html", owners: owners)
  end

  def change(%{assigns: %{study: study}} = conn, %{"owners" => selected_owners}) do
    owners_to_delete =
      selected_owners
      |> Enum.map(&String.to_integer/1)
      |> MapSet.new()

    owners =
      Studies.list_owners(study)
      |> Enum.reject(fn owner -> MapSet.member?(owners_to_delete, owner.id) end)

    :ok = Studies.assign_owners(study, owners)

    conn
    |> put_flash(:info, "Removed owners.")
    |> redirect(to: Routes.study_permissions_path(conn, :show, study))
  end

  def create(%{assigns: %{study: study}} = conn, %{"email" => email}) do
    case Users.get_by(email: email) do
      nil ->
        conn
        |> put_flash(:error, "User with #{email} does not exist.")
        |> show(%{})

      user ->
        Studies.add_owner!(study, user)

        conn
        |> put_flash(:info, "Added owner: #{email}.")
        |> redirect(to: Routes.study_permissions_path(conn, :show, study))
    end
  end
end
