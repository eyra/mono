defmodule Systems.Document.PDFView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  import Frameworks.Pixel.Line

  @impl true
  def update(%{title: title, url: url}, socket) do
    {
      :ok,
      socket
      |> assign(title: title, url: url)
      |> compose_element(:close_button)
      |> send_event(:parent, "tool_initialized")
    }
  end

  @impl true
  def compose(:close_button, %{myself: myself}) do
    %{
      action: %{type: :send, event: "close", target: myself},
      face: %{type: :primary, label: dgettext("eyra-ui", "close.button")}
    }
  end

  @impl true
  def handle_event("close", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "complete_task")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex flex-col w-full h-full gap-6 pl-sidepadding pt-sidepadding">
        <div class="flex flex-row items-center justify-center">
          <Text.title2 margin=""><%= @title %></Text.title2>
          <div class="flex-grow"/>
          <div>
            <Button.dynamic {@close_button} />
          </div>
        </div>
        <div class="flex-grow w-full" >
          <.line />
          <div id="pdf-viewer" phx-hook="PDFViewer" phx-update="ignore" data-src={"#{@url}"} />
        </div>
      </div>
    """
  end
end
