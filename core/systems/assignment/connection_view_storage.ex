defmodule Systems.Assignment.ConnectionViewStorage do
  use CoreWeb, :live_component

  alias Systems.{
    Assignment
  }

  @impl true
  def update(%{event: :disconnect}, %{assigns: %{assignment: assignment}} = socket) do
    Assignment.Public.delete_storage_endpoint!(assignment)
    {:ok, socket}
  end

  @impl true
  def update(%{assignment: assignment}, socket) do
    {
      :ok,
      socket
      |> assign(assignment: assignment)
    }
  end

  @impl true
  def handle_event("change", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
    </div>
    """
  end
end
