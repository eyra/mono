defmodule Systems.Console.Page do
  use Systems.Content.Composer, :live_workspace

  import Frameworks.Pixel.Content

  alias Frameworks.Pixel.Text

  alias Systems.NextAction

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}} = _socket) do
    user
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_uri(socket), do: socket

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={dgettext("eyra-ui", "dashboard.title")} menus={@menus} popup={@popup} dialog={@dialog}>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if @vm.next_best_action do %>
          <div>
            <NextAction.View.highlight {@vm.next_best_action} />
            <.spacing value="XL" />
          </div>
        <% end %>
        <Text.title2>
          <%= dgettext("eyra-dashboard", "recent-items.title") %>
          <span class="text-primary"> <%= Enum.count(@vm.content_items) %></span>
        </Text.title2>
        <.list items={@vm.content_items} />
      </Area.content>
    </.live_workspace>
    """
  end
end
