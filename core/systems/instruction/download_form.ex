defmodule Systems.Instruction.DownloadForm do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  @impl true
  def update(%{}, %{assigns: %{}} = socket) do
    {
      :ok,
      socket
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div></div>
    """
  end
end
