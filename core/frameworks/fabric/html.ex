defmodule Fabric.Html do
  use Phoenix.Component

  attr(:id, :any, required: true)
  attr(:fabric, :map, required: true)
  slot(:header)
  slot(:footer)

  def child(assigns) do
    ~H"""
      <%= if child = Fabric.get_child(@fabric, @id) do %>
        <%= render_slot(@header) %>
        <.live_component {Map.from_struct(child.ref)} {child.params}/>
        <%= render_slot(@footer) %>
      <% end %>
    """
  end
end
