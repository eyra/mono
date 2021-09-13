defmodule CoreWeb.Admin.Permissions do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :permissions

  import Ecto.Query
  alias Core.Repo
  alias Core.Accounts.User
  alias Core.Accounts

  alias EyraUI.Text.{BodyLarge, Title2, Title3}
  alias EyraUI.Button.Action.Send
  alias EyraUI.Button.Face.Icon

  data(researchers, :any)
  data(pool_admins, :any)
  data(pool_admin_candidates, :any)

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> update_pool_admin_data()
      |> update_menus()
    }
  end

  # FIXME: Move this to Accounts
  defp list_researchers do
    from(u in User, order_by: {:asc, :email})
    |> Repo.all()
    |> Enum.filter(& &1.researcher)
  end

  defp list_pool_admins do
    list_researchers()
    |> Enum.filter(& &1.coordinator)
  end

  defp list_pool_admin_candidates do
    list_researchers()
    |> Enum.filter(&(!&1.coordinator))
  end

  defp update_pool_admin_data(socket) do
    socket
    |> assign(:pool_admins, list_pool_admins())
    |> assign(:pool_admin_candidates, list_pool_admin_candidates())
  end

  def handle_event("assign_pool_admin_role", %{"item" => email}, socket) do
    user = Accounts.get_user_by_email(email)
    Accounts.update_user_profile(user, %{coordinator: true}, %{})

    {
      :noreply,
      socket |> update_pool_admin_data()
    }
  end

  def handle_event("remove_pool_admin_role", %{"item" => email}, socket) do
    user = Accounts.get_user_by_email(email)
    Accounts.update_user_profile(user, %{coordinator: false}, %{})

    {
      :noreply,
      socket |> update_pool_admin_data()
    }
  end

  def render(assigns) do
    ~H"""
    <Workspace
      title={{ dgettext("eyra-admin", "permissions.title") }}
      menus={{ @menus }}
    >
      <ContentArea class="mb-4" >
        <MarginY id={{:page_top}} />
        <Title2>{{ dgettext("eyra-admin", "permissions.pooladmin.title") }}</Title2>
        <BodyLarge>{{ dgettext("eyra-admin", "permissions.pooladmin.description") }}</BodyLarge>
        <Spacing value="XS" />
        <table class="table-auto">
          <tr :for={{user <- @pool_admins}}>
            <td class="pr-4">
              <Send vm={{ %{event: "remove_pool_admin_role", item: user.email} }}>
                <Icon vm={{ %{icon: :remove} }} />
              </Send>
            </td>
            <td><BodyLarge>{{user.email}}</BodyLarge></td>
          </tr>
        </table>
        <div :if={{ Enum.count(@pool_admin_candidates) > 0}}>
          <Spacing value="XL" />
          <Title3>{{ dgettext("eyra-admin", "permissions.pooladmin.candidates.title") }}</Title3>
          <Spacing value="XS" />
          <table class="table-auto">
            <tr :for={{user <- @pool_admin_candidates}}>
              <td class="pr-4">
                <Send vm={{ %{event: "assign_pool_admin_role", item: user.email} }}>
                  <Icon vm={{ %{icon: :add} }} />
                </Send>
              </td>
              <td><BodyLarge>{{user.email}}</BodyLarge></td>
            </tr>
          </table>
        </div>
      </ContentArea>
    </Workspace>
    """
  end
end
