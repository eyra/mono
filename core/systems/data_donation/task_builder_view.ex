defmodule Systems.DataDonation.TaskBuilderView do
  use CoreWeb, :live_component

  import Systems.DataDonation.TaskViews
  import Frameworks.Pixel.SidePanel

  @impl true
  def update(%{id: id, flow: flow, library: library}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        flow: flow,
        library: library
      )
    }
  end

  @impl true
  def handle_event("add", %{"item" => _item_id}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div  class="flex flex-row">
        <div class="flex-grow">
          <Area.content>
            <Margin.y id={:page_top} />
            <Text.title2><%= @flow.title %></Text.title2>
            <Text.body><%= @flow.description %></Text.body>
          </Area.content>
        </div>
        <div class="flex-shrink-0 w-side-panel">
          <.side_panel id={:library} >
            <Margin.y id={:page_top} />
            <.library {@library} />
          </.side_panel>
        </div>
      </div>
    </div>
    """
  end
end
