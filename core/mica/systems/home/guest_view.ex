defmodule Systems.Home.GuestView do
  use MicaWeb, :live_component_fabric
  import Systems.Home.HTML

  @impl true
  def update(%{sign_up_url: sign_up_url}, socket) do
    {:ok, assign(socket, sign_up_url: sign_up_url)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="home-guest-view">
      <div class="bg-grey6">
        <.intro />
        <.steps sign_up_url={@sign_up_url} />
        <.available_services />
        <.video />
      </div>
    </div>
    """
  end
end
