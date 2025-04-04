defmodule Systems.Manual.ToolView do
  use CoreWeb, :live_component

  alias Systems.Manual
  @impl true
  def update(%{manual: manual, title: title, user: user}, socket) do
    {:ok,
     socket
     |> assign(manual: manual, title: title, user: user)
     |> compose_child(:manual_view)}
  end

  @impl true
  def compose(:manual_view, %{manual: manual, title: title, user: user}) do
    %{
      module: Manual.View,
      params: %{
        manual: manual,
        title: title,
        user: user
      }
    }
  end

  def handle_event("back", _, socket) do
    {
      :noreply,
      socket |> send_event(:parent, "complete_task")
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.child name={:manual_view} fabric={@fabric} />
    </div>
    """
  end
end
