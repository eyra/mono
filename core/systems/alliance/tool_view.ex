defmodule Systems.Alliance.ToolView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Align
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  alias Systems.Alliance

  @impl true
  def update(%{title: title, tool: tool, participant: participant}, socket) do
    {
      :ok,
      socket
      |> assign(
        tool: tool,
        title: title,
        description: dgettext("eyra-alliance", "tool.description"),
        participant: participant
      )
      |> update_participant_url()
      |> update_button()
    }
  end

  defp update_participant_url(%{assigns: %{tool: tool, participant: participant}} = socket)
       when is_binary(participant) do
    participant_url =
      tool
      |> Alliance.ToolModel.safe_uri()
      |> URI.append_query(URI.encode_query(participant: participant))
      |> URI.to_string()

    assign(socket, participant_url: participant_url)
  end

  defp update_button(%{assigns: %{participant_url: participant_url}} = socket) do
    button = %{
      action: %{type: :http_get, to: participant_url, target: "_blank"},
      face: %{type: :primary, label: dgettext("eyra-alliance", "tool.button")}
    }

    assign(socket, button: button)
  end

  @impl true
  def render(assigns) do
    ~H"""
        <div class="w-full h-full">
        <Align.horizontal_center>
        <Area.sheet>
          <div class="flex flex-col gap-8 items-center px-8">
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
