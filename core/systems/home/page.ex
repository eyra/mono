defmodule Systems.Home.Page do
  use Systems.Content.Composer, :live_website

  alias Systems.Home
  alias Frameworks.Pixel.Hero

  @impl true
  def get_model(_params, _session, _socket) do
    Systems.Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> compose_child(:home_view)
    }
  end

  @impl true
  def compose(:home_view, %{vm: %{view_type: :guest}}) do
    %{
      module: Home.GuestView,
      params: %{}
    }
  end

  def compose(:home_view, %{vm: %{view_type: :logged_in, blocks: blocks}}) do
    %{
      module: Home.LoggedInView,
      params: %{
        blocks: blocks
      }
    }
  end

  @impl true
  def handle_view_model_updated(socket) do
    # FIXME: consider to move updates of childs to Fabric.LiveHook
    socket |> update_child(:home_view)
  end

  # Bubbled up by `RewardsSummaryView` after a successful payout — redirecting
  # has to happen here (a routed LiveView), not inside the component's update/2.
  def handle_info(:payout_completed, socket) do
    {:noreply, push_navigate(socket, to: ~p"/user/account?tab=payouts")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_website include_right_sidepadding?={@vm.include_right_sidepadding?} user={@current_user} user_agent={Browser.Ua.to_ua(@socket)} menus={@menus} modal={@modal} socket={@socket}>
      <:hero>
        <Hero.dynamic {@vm.hero} />
      </:hero>
      <div data-testid="home-page">
        <.child name={:home_view} fabric={@fabric} />
      </div>
    </.live_website>
    """
  end
end
