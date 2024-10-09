defmodule Systems.Content.PageView do
  use CoreWeb, :live_component

  alias Systems.Content

  @impl true
  def update(%{page: %Content.PageModel{body: body}}, socket) do
    {
      :ok,
      socket |> assign(body: body)
    }
  end

  def handle_event("close", _, socket) do
    {:noreply, socket |> send_event(:parent, "close_page")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <div class="wysiwyg">
          <%= raw @body %>
        </div>
      </div>
    """
  end
end
