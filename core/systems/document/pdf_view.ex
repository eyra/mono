defmodule Systems.Document.PDFView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  @impl true
  def update(%{key: key, url: url} = params, socket) do
    visible = Map.get(params, :visible, true)

    {
      :ok,
      socket
      |> assign(key: key, url: url, visible: visible)
      |> update_state()
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
  def render(assigns) do
    ~H"""
      <div class="flex-grow w-full h-full" >
        <div
          id={@key}
          class="flex flex-col w-full h-full overflow-x-scroll"
          phx-hook="PDFViewer"
          phx-update="ignore"
          data-src={"#{@url}"}
          data-state={@state} />
      </div>
    """
  end
end
