defmodule Systems.Graphite.ToolView do
  use CoreWeb, :modal_live_view
  use Core.FeatureFlags
  use Frameworks.Pixel

  import Frameworks.Pixel.Line

  alias Systems.Workflow

  def dependencies(), do: [:current_user, :timezone, :tool_ref]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{tool_ref: tool_ref}}) do
    Workflow.ToolRefModel.tool(tool_ref)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("go_to_leaderboard", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("done", _payload, socket) do
    {:noreply, publish_event(socket, :tool_completed)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-graphite", "submission.title") %></Text.title2>
        <.spacing value="M" />
        <div class="border-grey4 border-2 rounded p-6">
          <.live_component {@vm.submission_form} />
          <.spacing value="M" />
          <.line />
          <.spacing value="M" />

          <Text.title3><%= dgettext("eyra-graphite", "leaderboard.title") %></Text.title3>
          <.spacing value="XS" />

          <%= if feature_enabled?(:leaderboard) and @vm.leaderboard_button do %>
            <Text.body><%= dgettext("eyra-graphite", "leaderboard.published.message") %></Text.body>
            <.spacing value="S" />
            <Button.dynamic_bar buttons={[@vm.leaderboard_button]} />
          <% else %>
            <Text.body><%= @vm.leaderboard_description %></Text.body>
            <.spacing value="XS" />
          <% end %>
        </div>
        <.spacing value="M" />

        <%= if @vm.done_button do %>
          <Button.dynamic_bar buttons={[@vm.done_button]} />
        <% end %>
      </Area.content>
    </div>
    """
  end
end
