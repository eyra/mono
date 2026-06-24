defmodule Systems.Account.Page do
  @moduledoc """
  The Account page (`/user/account`).

  Renders inside the workspace layout for creators and the stripped
  layout (same as the auth and onboarding pages) for participants —
  `Account.PageBuilder` decides which, and which menu set to use,
  based on the current user.

  Within the chosen layout the body is an adaptable_layout: a single
  pane for users with one tab (the common case) and a tabbar for users
  with two or more (PANL participants get a Features tab). The Profile
  tab owns the Sign-out action.
  """
  use CoreWeb, :routed_live_view
  use Gettext, backend: CoreWeb.Gettext

  import Systems.Content.Html

  alias Core

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

  # Defer menus_config to the page builder so it can pick the menu set that
  # matches the layout (website for participants, workspace for creators).
  def get_menus_config(), do: nil

  def update_menus(
        %{
          assigns: %{
            vm: %{menus_config: {menu_builder, menus}, active_menu_item: active_menu_item}
          }
        } = socket
      ) do
    update_menus(socket, menu_builder, menus, active_menu_item)
  end

  def update_menus(socket), do: super(socket)

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
  def handle_view_model_updated(socket), do: socket

  @impl true
  def render(%{vm: %{layout: :stripped}} = assigns) do
    ~H"""
    <.live_stripped menus={@menus} modal={@modal} socket={@socket}>
      <.adaptable_layout
        socket={@socket}
        items={@vm.items}
        tabbar_id={@tabbar_id}
        initial_item={@initial_item}
      />
    </.live_stripped>
    """
  end

  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modal={@modal} socket={@socket}>
      <.adaptable_layout
        socket={@socket}
        items={@vm.items}
        tabbar_id={@tabbar_id}
        initial_item={@initial_item}
      />
    </.live_workspace>
    """
  end
end
