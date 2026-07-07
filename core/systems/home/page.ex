defmodule Systems.Home.Page do
  use Systems.Content.Composer, :live_website

  require Logger

  alias Systems.Home
  alias Systems.Pool
  alias Systems.Account
  alias Frameworks.Signal
  alias Frameworks.Pixel.Hero

  @impl true
  def get_model(_params, _session, _socket) do
    Systems.Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(params, _session, socket) do
    {
      :ok,
      socket
      |> assign(join_pool: nil, after_action: nil)
      |> compose_child(:home_view)
      |> maybe_show_join_pool_consent(params)
    }
  end

  # `?after=join_pool:<slug>` lands here after the OTP redeem (or any other
  # flow that carries the param via `Account.UserAuth.log_in_user/4`). If
  # the slug resolves to a real pool the user isn't already a member of,
  # show the informed-consent modal.
  defp maybe_show_join_pool_consent(
         %{assigns: %{current_user: %Account.User{} = user}} = socket,
         %{"after" => "join_pool:" <> slug = action}
       ) do
    with {:ok, slug_atom} <- safe_to_existing_atom(slug),
         %Pool.Model{} = pool <- Pool.Public.get_by_slug(slug_atom),
         false <- Pool.Public.participant?(pool, user) do
      socket
      |> assign(join_pool: pool, after_action: action)
      |> compose_child(:join_pool_consent_modal)
      |> Fabric.ModalController.show_modal(:join_pool_consent_modal, :compact)
    else
      _ -> socket
    end
  end

  defp maybe_show_join_pool_consent(socket, _params), do: socket

  defp safe_to_existing_atom(str) when is_binary(str) do
    {:ok, String.to_existing_atom(str)}
  rescue
    ArgumentError -> :error
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

  def compose(:join_pool_consent_modal, %{join_pool: %Pool.Model{} = pool}) do
    %{
      module: Pool.JoinConsentView,
      params: %{pool: pool}
    }
  end

  def compose(:join_pool_consent_modal, _assigns), do: nil

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
  def consume_event(
        %{name: :accept, source: %{name: :join_pool_consent_modal}},
        %{assigns: %{current_user: user, after_action: action}} = socket
      )
      when is_binary(action) do
    Signal.Public.dispatch({:account, :post_signup}, %{user: user, action: action})

    {:stop, socket |> close_join_consent_modal()}
  end

  def consume_event(%{name: :decline, source: %{name: :join_pool_consent_modal}}, socket) do
    {:stop, socket |> close_join_consent_modal()}
  end

  defp close_join_consent_modal(socket) do
    socket
    |> Fabric.ModalController.hide_modal(:join_pool_consent_modal)
    |> assign(join_pool: nil, after_action: nil)
    |> push_patch(to: ~p"/")
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
