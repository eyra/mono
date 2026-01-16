defmodule Systems.Account.UserProfilePage do
  @moduledoc """
  The user profile page with tabbed interface.
  """
  use Systems.Content.Composer, :live_workspace
  use Gettext, backend: CoreWeb.Gettext

  alias Core
  alias Frameworks.Pixel.Tabbed

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
        initial_tab: active_tab
      )
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modal={@modal} socket={@socket}>
      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex justify-center">
          <Tabbed.bar id={@tabbar_id} tabs={@vm.tabs} initial_tab={@initial_tab} size={:wide} type={:segmented} preserve_tab_in_url={true} />
        </div>
        <Margin.y id={:tabbar_content_top} />
        <Tabbed.content socket={@socket} bar_id={@tabbar_id} tabs={@vm.tabs} include_top_margin={false} />
      </Area.content>
    </.live_workspace>
    """
  end
end
