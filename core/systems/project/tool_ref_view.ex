defmodule Systems.Project.ToolRefView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Frameworks.Concept

  alias Systems.{
    Project
  }

  def update(%{id: id, tool_ref: tool_ref, task: task}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        tool_ref: tool_ref,
        task: task
      )
      |> compose_element(:launcher)
    }
  end

  @impl true
  def compose(:launcher, %{tool_ref: tool_ref}) do
    Project.ToolRefModel.tool(tool_ref)
    |> Concept.ToolModel.launcher()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full">
      <%= if @launcher do %>
        <.function_component {@launcher} />
      <% end %>
    </div>
    """
  end
end
