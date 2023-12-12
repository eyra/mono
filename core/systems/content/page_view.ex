defmodule Systems.Content.PageView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Systems.Content

  @impl true
  def update(%{page: %Content.PageModel{body: body}}, socket) do
    {
      :ok,
      socket |> assign(body: body)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <div class="wysiwig">
          <%= raw @body %>
        </div>
      </div>
    """
  end
end
