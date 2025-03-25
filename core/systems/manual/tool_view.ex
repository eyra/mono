defmodule Systems.Manual.ToolView do
  use CoreWeb, :live_component

  alias Systems.Manual
  @impl true
  def update(%{manual: manual, title: title, user: user}, socket) do
    {:ok,
     socket
     |> send_event(:parent, "tool_initialized")
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

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.child name={:manual_view} fabric={@fabric} />
    </div>
    """
  end
end
