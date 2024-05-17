defmodule Systems.Instruction.ToolView do
  use CoreWeb, :live_component

  import CoreWeb.Gettext

  alias Systems.Content

  @impl true
  def update(%{tool: tool}, socket) do
    {
      :ok,
      socket
      |> send_event(:parent, "tool_initialized")
      |> assign(tool: tool)
      |> update_page()
      |> update_done_button()
      |> compose_child(:page_view)
    }
  end

  defp update_page(%{assigns: %{tool: %{pages: [%{page: page} | _]}}} = socket) do
    socket |> assign(page: page)
  end

  defp update_page(socket) do
    socket |> assign(page: nil)
  end

  defp update_done_button(%{assigns: %{myself: myself}} = socket) do
    done_button = %{
      action: %{type: :send, event: "done", target: myself},
      face: %{type: :primary, label: dgettext("eyra-ui", "done.button")}
    }

    socket |> assign(done_button: done_button)
  end

  @impl true
  def compose(:page_view, %{page: nil}), do: nil

  @impl true
  def compose(:page_view, %{page: page}) do
    %{
      module: Content.PageView,
      params: %{
        page: page
      }
    }
  end

  @impl true
  def handle_event("done", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "complete_task")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-instruction", "page.title") %></Text.title2>
          <.child name={:page_view} fabric={@fabric} />
          <.spacing value="M" />
          <.wrap>
            <Button.dynamic {@done_button} />
          </.wrap>
        </Area.content>
      </div>
    """
  end
end
