defmodule Systems.Account.UserProfilePage do
  @moduledoc """
  The user profile page with tabbed interface.
  Uses LiveNest routed_live_view pattern with embedded views for tabs.
  """
  use CoreWeb, :routed_live_view
  use Gettext, backend: CoreWeb.Gettext

  import CoreWeb.Layouts.Workspace.Html

  alias Frameworks.Pixel.Navigation
  alias Frameworks.Pixel.Tabbed

  # Set up workspace hooks (excluding Fabric.LiveHook)
  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Viewport, __MODULE__})
  on_mount({CoreWeb.Live.Hook.RemoteIp, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Timezone, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Locale, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Model, __MODULE__})
  on_mount({Systems.Observatory.LiveHook, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Menus, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Tabbed, __MODULE__})

  def get_menus_config(),
    do: {
      :workspace_menu_builder,
      [
        :mobile_menu,
        :mobile_navbar,
        :desktop_menu,
        :tablet_menu
      ]
    }

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}} = _socket) do
    Core.Repo.preload(user, [:features, :profile])
  end

  @impl true
  def mount(params, _session, socket) do
    tabbar_id = "user_profile"

    active_tab =
      Map.get(params, "tab", "profile")
      |> String.to_existing_atom()

    {
      :ok,
      socket
      |> assign(
        tabbar_id: tabbar_id,
        initial_tab: active_tab,
        modal: nil,
        modal_toolbar_buttons: []
      )
    }
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={@vm.title} menus={@menus}>
      <:top_bar>
        <Navigation.action_bar breadcrumbs={[]} right_bar_buttons={[@vm.signout_button]} align={:center}>
          <Tabbed.bar id={@tabbar_id} tabs={@vm.tabs} initial_tab={@initial_tab} size={:wide} type={:segmented} preserve_tab_in_url={true} />
        </Navigation.action_bar>
      </:top_bar>
      <Tabbed.content socket={@socket} bar_id={@tabbar_id} tabs={@vm.tabs} />
    </.workspace>
    """
  end
end
