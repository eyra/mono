defmodule Systems.Storage.DonationPage do
  use Systems.Content.Composer, :live_workspace

  alias Frameworks.Pixel.Navigation
  alias Systems.Storage

  @impl true
  def get_authorization_context(params, session, socket) do
    get_model(params, session, socket)
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Storage.Public.get_endpoint!(
      String.to_integer(id),
      Storage.EndpointModel.preload_graph(:down)
    )
  end

  @impl true
  def mount(%{"path" => path}, _session, %{assigns: %{model: endpoint}} = socket) do
    {
      :ok,
      socket
      |> assign(path: path, donation: Storage.DonationView.read(endpoint, path))
      |> assign(run: run(endpoint, path))
      |> update_view_model()
    }
  end

  defp run(endpoint, path) do
    if Storage.DonationRun.summary?(path), do: Storage.DonationRun.prompts(endpoint, path)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modal={@modal} socket={@socket}>
      <:top_bar>
        <Navigation.action_bar breadcrumbs={@vm.breadcrumbs} right_bar_buttons={@vm.buttons}>
          <div />
        </Navigation.action_bar>
      </:top_bar>

      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex flex-col gap-10" data-testid="donation-page">
          <%= for {type, block} <- @vm.blocks do %>
            <.block type={type} {block} />
          <% end %>
        </div>
      </Area.content>
    </.live_workspace>
    """
  end

  defp block(%{type: :header} = assigns) do
    ~H"""
    <div data-testid="header-block">
      <Text.title2 margin=""><span class="break-all"><%= @title %></span></Text.title2>
      <.spacing value="S" />
      <div class="flex flex-row flex-wrap gap-x-10 gap-y-4">
        <%= for {label, value} <- @meta do %>
          <div class="flex flex-col gap-1">
            <Text.label color="text-grey2"><%= label %></Text.label>
            <Text.body_medium><span class="break-all"><%= value %></span></Text.body_medium>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp block(%{type: :run_charts} = assigns) do
    ~H"""
    <div data-testid="run-chart-block">
      <Text.title4><%= @title %></Text.title4>
      <.spacing value="XS" />
      <div class="border-[2px] border-grey4 rounded-lg p-4">
        <Storage.RunChartSVG.charts charts={@charts} labels={@labels} />
      </div>
    </div>
    """
  end

  defp block(%{type: :fields} = assigns) do
    ~H"""
    <div data-testid="fields-block">
      <Text.title4><%= @title %></Text.title4>
      <.spacing value="XS" />
      <div class="border-[2px] border-grey4 rounded-lg overflow-x-auto">
        <table class="min-w-full">
          <tbody>
            <%= for {key, value} <- @fields do %>
              <tr class="h-12 border-t first:border-t-0 border-grey4">
                <th class="w-1/4 pl-6 pr-4 py-3 text-left align-middle text-tablehead font-tablehead">
                  <%= key %>
                </th>
                <td class="pl-4 pr-6 py-3 align-middle text-tablerow font-tablerow break-all">
                  <%= value %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp block(%{type: :table} = assigns) do
    ~H"""
    <div data-testid="table-block">
      <div class="flex flex-row items-baseline gap-3">
        <Text.title4><%= @title %></Text.title4>
        <Text.title4><span class="text-primary"><%= @count %></span></Text.title4>
      </div>
      <.spacing value="XS" />
      <div class="border-[2px] border-grey4 rounded-lg overflow-x-auto">
        <table class="min-w-full">
          <thead>
            <tr>
              <%= for column <- @columns do %>
                <th class="h-12 px-4 first:pl-6 last:pr-6 text-left whitespace-nowrap text-tablehead font-tablehead">
                  <%= column %>
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody>
            <%= for row <- @rows do %>
              <tr class="h-12 border-t border-grey4">
                <%= for value <- row do %>
                  <td class="px-4 first:pl-6 last:pr-6 whitespace-nowrap text-tablerow font-tablerow">
                    <%= value %>
                  </td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp block(%{type: :message} = assigns) do
    ~H"""
    <div data-testid="message-block">
      <Text.body_large><%= @text %></Text.body_large>
    </div>
    """
  end
end
