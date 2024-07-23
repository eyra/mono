defmodule Systems.Pool.DetailPage do
  @moduledoc """
   The pool details screen.
  """
  use Systems.Content.Composer, :live_workspace
  use CoreWeb.UI.Responsive.Viewport

  alias Frameworks.Pixel.Tabbar
  alias Frameworks.Pixel.Navigation

  alias Systems.{
    Pool,
    Email
  }

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Pool.Public.get!(
      String.to_integer(id),
      Pool.Model.preload_graph([:org, :currency, :auth_node])
    )
  end

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "pool_detail/#{id}"

    {
      :ok,
      socket
      |> assign(
        id: id,
        tabbar_id: tabbar_id,
        initial_tab: initial_tab,
        email_dialog: nil,
        active_menu_item: :projects
      )
    }
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_uri(socket), do: socket

  @impl true
  def handle_event("close_email_dialog", _, socket) do
    {
      :noreply,
      socket
      |> close_email_dialog()
    }
  end

  def handle_info({:email_dialog, %Systems.Email.Model{} = email}, socket) do
    Email.Public.deliver_later!(email)

    {
      :noreply,
      socket
      |> close_email_dialog()
    }
  end

  def handle_info({:email_dialog, :close}, socket) do
    {
      :noreply,
      socket
      |> close_email_dialog()
    }
  end

  def handle_info(
        {:email_dialog, %{recipients: recipients}},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    {
      :noreply,
      socket
      |> assign(
        email_dialog: %{
          module: Email.Dialog,
          id: :email_dialog,
          users: recipients,
          current_user: current_user
        }
      )
    }
  end

  def handle_info({:claim_focus, :email_form}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_resize(socket) do
    socket
    |> update_menus()
  end

  defp close_email_dialog(socket) do
    socket
    |> assign(email_dialog: nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modal={@modal} popup={@popup} dialog={@dialog}>
      <%= if @email_dialog do %>
        <div
          class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20"
          phx-click="close_email_dialog"
        >
          <div class="flex flex-row items-center justify-center w-full h-full">
            <.live_component {@email_dialog} />
          </div>
        </div>
      <% end %>

      <div id={:pool_detail} phx-hook="ViewportResize">
        <Navigation.action_bar breadcrumbs={[]}>
          <Tabbar.container id={@tabbar_id} tabs={@vm.tabs} initial_tab={@initial_tab} size={:wide} type={:segmented} />
        </Navigation.action_bar>
        <Tabbar.content tabs={@vm.tabs} />
      </div>
    </.live_workspace>
    """
  end
end
