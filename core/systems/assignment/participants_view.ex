defmodule Systems.Assignment.ParticipantsView do
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
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-assignment", "participants.title") %></Text.title2>
          <.spacing value="L" />
        </Area.content>
      </div>
    """
  end
end
