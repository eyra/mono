defmodule Systems.Account.UserProfilePage do
  @moduledoc """
  The user profile page with adaptable layout.
  Uses single layout for 1 item (most users), tabbed for 2+ items (PANL participants).
  """
  use Systems.Content.Composer, :live_workspace
  use Gettext, backend: CoreWeb.Gettext

  alias Core

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
