defmodule Systems.Assignment.StartView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Frameworks.Pixel.Align
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text
  alias Frameworks.Concept

  alias Systems.Project

  def update(%{id: id, work_item: work_item, loading: loading}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        work_item: work_item,
        loading: loading
      )
      |> compose_element(:title)
      |> compose_element(:description)
      |> compose_element(:icon)
      |> compose_element(:button)
    }
  end

  @impl true
  def compose(:button, %{work_item: work_item, loading: loading}) do
    %{
      action: start_action(work_item),
      face: %{type: :primary, label: "Start", loading: loading}
    }
  end

  @impl true
  def compose(:title, %{work_item: {%{title: title}, _}}), do: title

  @impl true
  def compose(:description, %{work_item: {%{description: description}, _}}), do: description

  @impl true
  def compose(:icon, %{work_item: {%{group: nil}, _}}), do: nil

  @impl true
  def compose(:icon, %{work_item: {%{group: group}, _}}), do: String.downcase(group)

  defp start_action({%{tool_ref: tool_ref}, _task} = item) do
    Project.ToolRefModel.tool(tool_ref)
    |> Concept.ToolModel.launcher()
    |> start_action(item)
  end

  defp start_action(%{url: url}, _) do
    %{type: :http_get, to: url, target: "_blank"}
  end

  defp start_action(_, _) do
    %{type: :send, event: "start"}
  end

  @impl true
  def handle_event("start", _, socket) do
    {
      :noreply,
      socket
      |> assign(loading: true)
      |> compose_element(:button)
      |> send_event(:parent, "start")
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="w-full h-full">
        <Align.horizontal_center>
        <Area.sheet>
          <div class="flex flex-col gap-8 items-center">
              <div>
              <%= if @icon do %>
                <img class="w-24 h-24" src={~p"/images/icons/#{"#{@icon}_square.svg"}"} onerror="this.src='/images/icons/placeholder_square.svg';" alt={@icon}>
              <% end %>
            </div>
            <Text.title2 margin=""><%= @title %></Text.title2>
            <Text.body align="text-center"><%= @description %></Text.body>
            <.wrap>
              <Button.dynamic {@button} />
            </.wrap>
          </div>
        </Area.sheet>
        </Align.horizontal_center>
      </div>
    """
  end
end
