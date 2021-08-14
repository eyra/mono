defmodule CoreWeb.Admin.CoordinatorManagement do
  use CoreWeb, :live_view
  import Ecto.Query
  alias Core.Repo
  alias Core.Accounts.User
  alias Core.Accounts

  data(users, :any)

  def mount(_params, _session, socket) do
    {
      :ok,
      socket |> assign(:users, list_users())
    }
  end

  # FIXME: Move this to Accounts
  defp list_users do
    from(u in User, order_by: {:asc, :email})
    |> Repo.all()
  end

  def handle_event("assign_coorinator_role", %{"email" => email}, socket) do
    user = Accounts.get_user_by_email(email)
    Accounts.update_user_profile(user, %{coordinator: true}, %{})
    {:noreply, socket |> assign(:users, list_users())}
  end

  def handle_event("remove_coorinator_role", %{"email" => email}, socket) do
    user = Accounts.get_user_by_email(email)
    Accounts.update_user_profile(user, %{coordinator: false}, %{})
    {:noreply, socket |> assign(:users, list_users())}
  end

  def render(assigns) do
    ~H"""
    <div>
    Admin
    <table>
    <tr :for={{user <- @users}}>
      <td>{{user.email}}</td>
      <td :if={{user.coordinator}} :on-click="remove_coorinator_role" phx-value-email={{user.email}}>
      Remove coorinator role
      </td>
      <td :if={{!user.coordinator}} :on-click="assign_coorinator_role" phx-value-email={{user.email}}>
        Assign coordinator role
      </td>
    </tr>
    </table>
    </div>
    """
  end
end
