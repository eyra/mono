defmodule Systems.Benchmark.ToolPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :projects
  use Systems.Observatory.Public

  alias Frameworks.Pixel.{
    Align,
    Card
  }

  alias Systems.{
    Benchmark
  }

  @impl true
  def get_authorization_context(%{"id" => id, "spot" => spot_id}, _session, %{
        assigns: %{current_user: _user}
      }) do
    Benchmark.Public.get_spot_for_tool(String.to_integer(id), String.to_integer(spot_id))
  end

  @impl true
  def mount(%{"id" => id, "spot" => spot_id}, _session, socket) do
    model =
      Benchmark.Public.get_tool!(String.to_integer(id), Benchmark.ToolModel.preload_graph(:down))

    {
      :ok,
      socket
      |> assign(
        model: model,
        spot_id: spot_id,
        popup: nil
      )
      |> observe_view_model()
    }
  end

  @impl true
  def handle_info({:handle_auto_save_done, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:show_popup, popup}, socket) do
    {:noreply, socket |> show_popup(popup)}
  end

  @impl true
  def handle_info({:hide_popup}, socket) do
    {:noreply, socket |> hide_popup()}
  end

  defp show_popup(socket, popup) do
    socket |> assign(popup: popup)
  end

  defp hide_popup(socket) do
    socket |> assign(popup: nil)
  end

  defp grid_cols(1), do: "grid-cols-1 sm:grid-cols-1"
  defp grid_cols(2), do: "grid-cols-1 sm:grid-cols-2"
  defp grid_cols(_), do: "grid-cols-1 sm:grid-cols-3"

  @impl true
  def render(assigns) do
    ~H"""
      <.stripped title={@vm.hero_title} menus={@menus}>
        <%= if @popup do %>
          <.popup>
            <div class="p-8 w-popup-md bg-white shadow-floating rounded">
              <.live_component {@popup} />
            </div>
          </.popup>
        <% end %>

        <Area.content>
          <Margin.y id={:page_top} />
          <Align.horizontal_center>
            <Text.title1><%= @vm.title %></Text.title1>
          </Align.horizontal_center>
          <.spacing value="M" />

          <div class={"grid gap-6 sm:gap-8 #{grid_cols(Enum.count(@vm.highlights))}"}>
            <%= for highlight <- @vm.highlights do %>
              <div class="bg-grey5 rounded">
                <Card.highlight {highlight} />
              </div>
            <% end %>
          </div>
          <.spacing value="XL" />

          <Text.title2><%= dgettext("eyra-benchmark", "expectations.title") %></Text.title2>
          <Text.body><%= raw(@vm.expectations) %></Text.body>
          <%!-- <.spacing value="XS" />
          <Text.sub_head><%= dgettext("eyra-benchmark", "expectations.subhead") %></Text.sub_head> --%>
          <.spacing value="XL" />

          <Text.title2><%= dgettext("eyra-benchmark", "preparation.title") %></Text.title2>
          <Text.body><%= dgettext("eyra-benchmark", "preparation.description") %></Text.body>
          <.spacing value="XS" />
          <Text.title5 align="text-left">1. <%= dgettext("eyra-benchmark", "preparation.dataset.title") %></Text.title5>
          <.spacing value="M" />
          <%= if @vm.dataset_button do %>
            <div class="ml-6">
              <.wrap>
                <Button.dynamic {@vm.dataset_button} />
              </.wrap>
            </div>
          <% end %>
          <.spacing value="M" />

          <Text.title5 align="text-left">2. <%= dgettext("eyra-benchmark", "preparation.template.title") %></Text.title5>
          <.spacing value="XS" />
          <Text.title5 align="ml-6 text-left"><Button.dynamic {@vm.template_button} /></Text.title5>
          <.spacing value="XL" />

          <.live_component {@vm.spot_form} />
          <.spacing value="L" />

          <.live_component {@vm.submission_list_form} />
          <.spacing value="XL" />

          <%= if @vm.leaderboard do %>
            <div class="flex flex-row items-center">
              <Text.title2 margin=""><%= @vm.leaderboard.title %></Text.title2>
              <div class="flex-grow" />
              <Button.dynamic {@vm.leaderboard.forward_button} />
            </div>
            <.spacing value="M" />
            <.live_component {@vm.leaderboard.component} />
          <% end %>

        </Area.content>
      </.stripped>
    """
  end
end
