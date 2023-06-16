defmodule Systems.DataDonation.DocumentTaskView do
  use CoreWeb, :live_component

  @impl true
  def update(%{id: id, entity_id: entity_id}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id
      )
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    """
  end
end
