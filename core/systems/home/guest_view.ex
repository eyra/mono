defmodule Systems.Home.GuestView do
  use CoreWeb, :live_component
  import Systems.Home.HTML

  @impl true
  def update(_params, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="bg-grey6">
        <.intro />
        <.steps />
        <.available_services />
        <.video />
      </div>
    </div>
    """
  end
end
