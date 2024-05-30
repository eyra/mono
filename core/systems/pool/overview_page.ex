defmodule Systems.Pool.OverviewPage do
  @moduledoc """
   The pool overview screen.
  """
  use Systems.Content.Composer, :live_workspace

  import CoreWeb.Gettext

  alias Frameworks.Pixel.ShareView

  alias Systems.{
    Pool
  }

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}} = _socket) do
    user
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
    }
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_uri(socket), do: socket

  @impl true
  def compose(:share_view, %{active_pool: pool}) do
    researchers = Systems.Account.Public.list_creators([:profile])
    owners = Core.Authorization.users_with_role(pool, :owner, [:profile])

    %{
      module: ShareView,
      params: %{
        content_name: dgettext("eyra-pool", "share.dialog.content"),
        group_name: dgettext("eyra-pool", "share.dialog.group"),
        users: researchers,
        shared_users: owners
      }
    }
  end

  @impl true
  def handle_event("handle_pool_click", %{"item" => pool_id}, socket) do
    pool_id = String.to_integer(pool_id)
    {:noreply, push_redirect(socket, to: ~p"/pool/#{pool_id}/detail")}
  end

  @impl true
  def handle_event("share", %{"item" => pool_id}, socket) do
    pool = Pool.Public.get!(String.to_integer(pool_id))

    {
      :noreply,
      socket
      |> assign(active_pool: pool)
      |> compose_child(:share_view)
      |> show_popup(:share_view)
    }
  end

  @impl true
  def handle_event("finish", %{source: %{name: popup}}, socket) do
    {
      :noreply,
      socket
      |> hide_popup(popup)
    }
  end

  @impl true
  def handle_event("add_user", %{user: user}, %{assigns: %{active_pool: pool}} = socket) do
    Pool.Public.add_owner!(pool, user)
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_user", %{user: user}, %{assigns: %{active_pool: pool}} = socket) do
    Pool.Public.remove_owner!(pool, user)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={dgettext("eyra-pool", "overview.title")} menus={@menus} modal={@modal} popup={@popup} dialog={@dialog}>
      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex flex-col gap-20">
          <%= for plugin <- @vm.plugins do %>
            <.live_component module={plugin.module} {plugin.props} />
          <% end %>
        </div>
      </Area.content>
    </.live_workspace>
    """
  end
end
