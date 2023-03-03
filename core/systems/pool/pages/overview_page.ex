defmodule Systems.Pool.OverviewPage do
  @moduledoc """
   The student overview screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :pools
  use CoreWeb.UI.Responsive.Viewport

  import CoreWeb.Gettext

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias Frameworks.Pixel.ShareView

  alias Systems.{
    Pool
  }

  data(plugins, :list)
  data(popup, :any, default: nil)

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    plugins =
      Pool.Public.list_directors()
      |> Enum.map(& &1.overview_plugin(user))

    {
      :ok,
      socket |> assign(plugins: plugins)
    }
  end

  @impl true
  def handle_resize(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_event("share", %{"item" => pool_id}, socket) do
    researchers = Core.Accounts.list_researchers([:profile])

    owners =
      pool_id
      |> String.to_integer()
      |> Pool.Public.get!()
      |> Core.Authorization.users_with_role(:owner, [:profile])

    popup = %{
      module: ShareView,
      content_id: pool_id,
      content_name: dgettext("eyra-pool", "share.dialog.content"),
      group_name: dgettext("eyra-pool", "share.dialog.group"),
      users: researchers,
      shared_users: owners
    }

    {:noreply, socket |> show_popup(popup)}
  end

  @impl true
  def handle_info(%{module: ShareView, action: :close}, socket) do
    {:noreply, socket |> hide_popup()}
  end

  @impl true
  def handle_info(%{module: ShareView, action: %{add: user, content_id: pool_id}}, socket) do
    pool_id
    |> Pool.Public.get!()
    |> Pool.Public.add_owner!(user)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{module: ShareView, action: %{remove: user, content_id: pool_id}}, socket) do
    pool_id
    |> Pool.Public.get!()
    |> Pool.Public.remove_owner!(user)

    {:noreply, socket}
  end

  defp show_popup(socket, popup) do
    socket |> assign(popup: popup)
  end

  defp hide_popup(socket) do
    socket |> assign(popup: nil)
  end

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("eyra-pool", "overview.title")} menus={@menus}>
      <Popup :if={@popup}>
        <div class="p-8 w-popup-md bg-white shadow-2xl rounded">
          <Dynamic.LiveComponent id={:pool_overview_popup} module={@popup.module} {...@popup} />
        </div>
      </Popup>

      <div id={:pool_overview} phx-hook="ViewportResize">
        <ContentArea>
          <MarginY id={:page_top} />
          <div class="flex flex-col gap-20">
            <Dynamic.LiveComponent :for={plugin <- @plugins} module={plugin.module} {...plugin.props} />
          </div>
        </ContentArea>
      </div>
    </Workspace>
    """
  end
end
