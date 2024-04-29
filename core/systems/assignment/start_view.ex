defmodule Systems.Assignment.StartView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Frameworks.Pixel.Align
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text
  alias Frameworks.Concept

  alias Systems.Workflow

  def update(%{id: id, participant: participant, work_item: work_item, loading: loading}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        participant: participant,
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
  def compose(:button, %{participant: participant, work_item: work_item, loading: loading}) do
    %{
      action: start_action(work_item, participant),
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

  defp start_action({%{tool_ref: tool_ref}, _task} = item, participant) do
    Workflow.ToolRefModel.tool(tool_ref)
    |> Concept.ToolModel.launcher()
    |> start_action(item, participant)
  end

  defp start_action(%{url: %URI{} = url}, _, participant) do
    participant_url =
      url
      |> URI.append_query(URI.encode_query(participant: participant))
      |> URI.to_string()

    %{type: :http_get, to: participant_url, target: "_blank"}
  end

  defp start_action(_, _, _) do
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
          <div class="flex flex-col gap-8 items-center px-8">
              <div>
              <%= if @icon do %>
                <img class="w-24 h-24" src={~p"/images/icons/#{"#{@icon}_square.svg"}"} onerror="this.src='/images/icons/placeholder_square.svg';" alt={@icon}>
              <% end %>
            </div>
            <Text.title2 align="text-center" margin=""><%= @title %></Text.title2>
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
