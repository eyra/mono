defmodule Systems.Admin.ClientActivityView do
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text

  alias Systems.Observatory

  def dependencies(), do: [:is_admin?]

  def get_model(:not_mounted_at_router, _session, _assigns) do
    Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, assign(socket, active_filters: [], client_id: nil, assignment_id: nil)}
  end

  @impl true
  def handle_event("select_client", %{"item" => client_id}, socket) do
    {
      :noreply,
      socket
      |> assign(client_id: String.to_integer(client_id), assignment_id: nil)
      |> update_view_model()
    }
  end

  @impl true
  def handle_event("select_assignment", %{"item" => assignment_id}, socket) do
    {
      :noreply,
      socket
      |> assign(assignment_id: String.to_integer(assignment_id))
      |> update_view_model()
    }
  end

  @impl true
  def handle_event("back", _params, %{assigns: %{assignment_id: nil}} = socket) do
    {:noreply, socket |> assign(client_id: nil) |> update_view_model()}
  end

  @impl true
  def handle_event("back", _params, socket) do
    {:noreply, socket |> assign(assignment_id: nil) |> update_view_model()}
  end

  @impl true
  def consume_event(
        %{name: :active_item_ids, payload: %{active_item_ids: active_filters}},
        socket
      ) do
    {
      :stop,
      socket
      |> assign(active_filters: active_filters)
      |> update_view_model()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="client-activity-view">
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2 testid="client-activity-title">
          <%= @vm.title %>
          <%= if @vm.title_count do %>
            <span class="text-primary"><%= @vm.title_count %></span>
          <% end %>
        </Text.title2>
        <%= if @vm.level.type in [:clients, :client] do %>
          <div class="flex flex-row gap-3 items-center">
            <div class="font-label text-label"><%= @vm.filter_label %></div>
            <.live_component
              module={Selector}
              id={:client_activity_filters}
              items={@vm.filter_labels}
              type={:label}
            />
          </div>
          <.spacing value="XS" />
          <Text.hint testid="client-activity-filter-hint"><%= @vm.filter_hint %></Text.hint>
          <.spacing value="M" />
        <% end %>
        <.level level={@vm.level} />
        <.spacing value="XL" />
      </Area.content>
    </div>
    """
  end

  attr(:level, :map, required: true)

  defp level(%{level: %{type: :clients}} = assigns) do
    ~H"""
    <div data-testid="client-list">
      <%= if @level.clients == [] do %>
        <Text.body><%= @level.empty %></Text.body>
      <% else %>
        <table class="w-full">
          <thead>
            <tr class="h-10 text-left">
              <th><Text.table_head><%= @level.head.client %></Text.table_head></th>
              <th><Text.table_head><%= @level.head.email %></Text.table_head></th>
              <th class="text-right"><Text.table_head align="text-right"><%= @level.head.assignments %></Text.table_head></th>
            </tr>
          </thead>
          <tbody>
            <%= for client <- @level.clients do %>
              <tr
                class="h-12 border-t border-grey4 cursor-pointer hover:bg-grey6"
                phx-click="select_client"
                phx-value-item={client.id}
                data-testid={"client-row-#{client.id}"}
              >
                <td><Text.label><%= client.name %></Text.label></td>
                <td><Text.body_small><%= client.email %></Text.body_small></td>
                <td class="text-right">
                  <Text.label testid={"client-count-#{client.id}"}><%= client.assignment_count %></Text.label>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp level(%{level: %{type: :client}} = assigns) do
    ~H"""
    <div data-testid="client-assignment-list">
      <.back label={@level.back_label} />
      <Text.title3><%= @level.client.name %> <span class="text-primary"><%= @level.count %></span></Text.title3>
      <Text.body_small color="text-grey2"><%= @level.client.email %></Text.body_small>
      <.spacing value="S" />
      <%= if @level.assignments == [] do %>
        <Text.body><%= @level.empty %></Text.body>
      <% else %>
        <table class="w-full">
          <thead>
            <tr class="h-10 text-left">
              <th><Text.table_head><%= @level.head.name %></Text.table_head></th>
              <th><Text.table_head><%= @level.head.status %></Text.table_head></th>
              <th><Text.table_head><%= @level.head.created %></Text.table_head></th>
            </tr>
          </thead>
          <tbody>
            <%= for assignment <- @level.assignments do %>
              <tr
                class="h-12 border-t border-grey4 cursor-pointer hover:bg-grey6"
                phx-click="select_assignment"
                phx-value-item={assignment.id}
                data-testid={"assignment-row-#{assignment.id}"}
              >
                <td><Text.label><%= assignment.name %></Text.label></td>
                <td><Text.body_small><%= assignment.status %></Text.body_small></td>
                <td><Text.body_small><%= assignment.created %></Text.body_small></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp level(%{level: %{type: :assignment}} = assigns) do
    ~H"""
    <div data-testid="client-assignment-details">
      <.back label={@level.back_label} />
      <Text.title3><%= @level.name %></Text.title3>
      <table class="w-full">
        <tbody>
          <%= for detail <- @level.details do %>
            <tr class="h-10 border-t border-grey4">
              <td class="w-48"><Text.label><%= detail.label %></Text.label></td>
              <td><Text.body_small><%= detail.value %></Text.body_small></td>
            </tr>
          <% end %>
        </tbody>
      </table>
      <.spacing value="L" />
      <Text.title4><%= @level.team_title %></Text.title4>
      <.spacing value="XS" />
      <table class="w-full" data-testid="assignment-team">
        <tbody>
          <%= for member <- @level.team do %>
            <tr class="h-10 border-t border-grey4" data-testid={"team-member-#{member.id}"}>
              <td><Text.label><%= member.name %></Text.label></td>
              <td><Text.body_small><%= member.email %></Text.body_small></td>
              <td class="text-right">
                <%= if member.client? do %>
                  <Text.body_small color="text-primary"><%= member.client_label %></Text.body_small>
                <% end %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp level(%{level: %{type: :forbidden}} = assigns) do
    ~H"""
    <div data-testid="client-activity-forbidden"></div>
    """
  end

  attr(:label, :string, required: true)

  defp back(assigns) do
    ~H"""
    <div
      class="flex flex-row items-center gap-2 cursor-pointer mb-4"
      phx-click="back"
      data-testid="client-activity-back"
    >
      <img src={~p"/images/icons/back.svg"} alt="" />
      <Text.label color="text-grey1"><%= @label %></Text.label>
    </div>
    """
  end
end
