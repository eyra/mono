defmodule Systems.Account.UserProfilePage do
  @moduledoc """
  The user profile page with adaptable layout.
  Uses single layout for 1 item (most users), tabbed for 2+ items (PANL participants).
  """
  use CoreWeb, :routed_live_view
  use Gettext, backend: CoreWeb.Gettext

  import Systems.Content.Html

  alias Core

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

    initial_item =
      case Map.get(params, "tab") do
        nil -> nil
        tab -> String.to_existing_atom(tab)
      end

    {
      :ok,
      socket
      |> assign(
        tabbar_id: tabbar_id,
        initial_item: initial_item
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
    <.live_workspace title={@vm.title} menus={@menus} modal={@modal} socket={@socket}>
      <.adaptable_layout
        socket={@socket}
        items={@vm.items}
        tabbar_id={@tabbar_id}
        initial_item={@initial_item}
        toolbar_buttons={[@vm.signout_button]}
      />
    </.live_workspace>
    """
  end
end
