defmodule Systems.Document.PDFNavView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Systems.Document

  @impl true
  def update(%{key: key, title: title, url: url} = params, socket) do
    visible = Map.get(params, :visible, true)

    {
      :ok,
      socket
      |> assign(key: key, title: title, url: url, visible: visible)
      |> update_state()
      |> compose_element(:close_button)
      |> compose_element(:ready_button)
      |> compose_child(:pdf_view)
    }
  end

  defp update_state(%{assigns: %{visible: visible}} = socket) do
    state =
      if visible do
        "visible"
      else
        "hidden"
      end

    assign(socket, state: state)
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
  def compose(:pdf_view, %{key: key, url: url, visible: visible}) do
    %{
      module: Document.PDFView,
      params: %{
        key: key,
        url: url,
        visible: visible,
        title: dgettext("eyra-assignment", "privacy.title")
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
          phx-hook="Sticky"
          class="flex flex-row items-center justify-center h-[96px] px-8 w-full bg-white absolute lg:pl-sidepadding"
          data-class-default="md:pr-0 absolute"
          data-class-sticky="md:pr-[129px] fixed top-0"
          data-state={@state}
        >
          <Text.title2 margin=""><%= @title %></Text.title2>
          <div class="flex-grow"/>
          <div>
            <Button.dynamic {@close_button} />
          </div>
        </div>
        <div class="flex flex-col w-full h-full pt-[72px] sm:pt-[48px] pb-sidepadding">
          <.child name={:pdf_view} fabric={@fabric} />
        </div>
      </div>
    """
  end
end
