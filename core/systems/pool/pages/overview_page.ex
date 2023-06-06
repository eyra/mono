defmodule Systems.Pool.OverviewPage do
  @moduledoc """
   The student overview screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :pools

  import CoreWeb.Gettext

  import CoreWeb.Layouts.Workspace.Component
  alias Frameworks.Pixel.ShareView

  alias Systems.{
    Pool
  }

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    plugins =
      Pool.Public.list_directors()
      |> Enum.map(& &1.overview_plugin(user))

    {
      :ok,
      socket
      |> assign(
        plugins: plugins,
        popup: nil
      )
    }
  end

  @impl true
  def handle_event("handle_pool_click", %{"item" => pool_id}, socket) do
    pool_id = String.to_integer(pool_id)
    detail_path = Routes.live_path(socket, Systems.Pool.DetailPage, pool_id)
    {:noreply, push_redirect(socket, to: detail_path)}
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

  # data(plugins, :list)
  # data(popup, :any, default: nil)

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-pool", "overview.title")} menus={@menus}>
      <%= if @popup do %>
        <.popup>
          <div class="p-8 w-popup-md bg-white shadow-2xl rounded">
            <.live_component id={:pool_overview_popup} module={@popup.module} {@popup} />
          </div>
        </.popup>
      <% end %>

      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex flex-col gap-20">
          <%= for plugin <- @plugins do %>
            <.live_component module={plugin.module} {plugin.props} />
          <% end %>
        </div>
      </Area.content>
    </.workspace>
    """
  end
end
