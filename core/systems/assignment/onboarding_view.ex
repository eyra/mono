defmodule Systems.Assignment.OnboardingView do
  use CoreWeb, :embedded_live_view
  use CoreWeb, :verified_routes

  alias Frameworks.Pixel.Button
  alias CoreWeb.UI.Area
  alias CoreWeb.UI.Margin

  alias Systems.{Account, Assignment}

  def dependencies(), do: [:assignment_id, :current_user]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    Assignment.Public.get!(assignment_id, Assignment.Model.preload_graph(:down))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event(
        "continue",
        _payload,
        %{
          assigns: %{
            current_user: user,
            vm: %{page_ref: %{key: key, assignment_id: assignment_id}}
          }
        } = socket
      ) do
    Account.Public.mark_as_visited(user, {key, assignment_id})

    {
      :noreply,
      socket |> publish_event(:onboarding_continue)
    }
  end

  @impl true
  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <%= if @vm.content_page do %>
            <.live_component {@vm.content_page} />
          <% end %>
          <.spacing value="M" />
          <.wrap>
            <Button.dynamic {@vm.continue_button} />
          </.wrap>
        </Area.content>
      </div>
    """
  end
end
