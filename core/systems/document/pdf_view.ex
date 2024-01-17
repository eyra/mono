defmodule Systems.Document.PDFView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  @impl true
  def update(%{key: key, title: title, url: url} = params, socket) do
    visible = Map.get(params, :visible, true)

    state =
      if visible do
        "visible"
      else
        "hidden"
      end

    Logger.warning("[PDFView] state: #{state}")

    {
      :ok,
      socket
      |> assign(key: key, title: title, url: url, state: state)
      |> compose_element(:close_button)
      |> compose_element(:ready_button)
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
  def compose(:ready_button, %{myself: myself}) do
    %{
      action: %{type: :send, event: "close", target: myself},
      face: %{
        type: :primary,
        bg_color: "bg-success",
        label: dgettext("eyra-document", "ready.button")
      }
    }
  end

  @impl true
  def handle_event("close", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "complete_task")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="relative w-full h-full">
        <div
          id="pdf-viewer-navbar"
          class="flex flex-row items-center justify-center pl-sidepadding w-full h-[96px] bg-white absolute"
          phx-hook="Sticky",
          data-state={@state}
        >
          <Text.title2 margin=""><%= @title %></Text.title2>
          <div class="flex-grow"/>
          <div>
            <Button.dynamic {@close_button} />
          </div>
        </div>
        <div class="flex flex-col w-full h-full pt-[48px] pb-sidepadding">
          <div class="flex-grow w-full h-full" >
            <div
              id={@key}
              class="flex flex-col w-full h-full overflow-x-scroll"
              phx-hook="PDFViewer"
              phx-update="ignore"
              data-src={"#{@url}"}
              data-state={@state} />
          </div>
        </div>
      </div>
    """
  end
end
