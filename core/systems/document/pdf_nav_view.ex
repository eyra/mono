defmodule Systems.Document.PDFNavView do
  use CoreWeb, :live_component
  import Frameworks.Pixel.Line

  alias Systems.Document

  @impl true
  def update(%{key: key, title: title, url: url}, socket) do
    initialized = Map.get(socket.assigns, :initialized, false)

    {
      :ok,
      socket
      |> assign(key: key, title: title, url: url, initialized: initialized)
      |> compose_element(:ready_button)
      |> compose_child(:pdf_view)
    }
  end

  @impl true
  def compose(:ready_button, %{myself: myself}) do
    %{
      action: %{type: :send, event: "complete", target: myself},
      face: %{
        type: :primary,
        bg_color: "bg-success",
        label: dgettext("eyra-document", "ready.button")
      }
    }
  end

  @impl true
  def compose(:pdf_view, %{key: key, url: url}) do
    %{
      module: Document.PDFView,
      params: %{
        key: key,
        url: url,
        visible: true,
        title: dgettext("eyra-assignment", "privacy.title")
      }
    }
  end

  def handle_event("tool_initialized", _payload, socket) do
    {
      :noreply,
      socket
      |> assign(initialized: true)
    }
  end

  @impl true
  def handle_event("complete", _payload, socket) do
    {
      :noreply,
      socket
      |> send_event(:parent, "complete_task_and_close")
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row w-full h-full justify-center" >
      <div class="flex-grow"/>
      <div class="w-full h-full max-w-[1200px] p-4 lg:p-8 ">
        <div class="w-full">
          <div
            class="flex flex-row items-center w-full gap-4"
            data-state="visible"
          >
            <Text.title2 margin=""><%= @title %></Text.title2>
            <div class="flex-grow"/>
          </div>
          <.spacing value="M" />
          <.line />
          <div class="flex flex-col w-full h-full">
            <div>
              <.child name={:pdf_view} fabric={@fabric} />
            </div>
            <.spacing value="M" />
            <div class="flex flex-row-reverse w-full pb-4 lg:pb-8">
              <div>
                <Button.dynamic {@ready_button} />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="flex-grow"/>
    </div>
    """
  end
end
