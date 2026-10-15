defmodule Fabric.Html do
  use Phoenix.Component

  attr(:name, :any, required: true)
  attr(:fabric, :map, required: true)
  slot(:header)
  slot(:footer)

  def child(assigns) do
    ~H"""
      <%= if child = Fabric.get_child(@fabric, @name) do %>
        <%= render_slot(@header) %>
        <.live_child {Map.from_struct(child)} />
        <%= render_slot(@footer) %>
      <% end %>
    """
  end

  attr(:fabric, :map, required: true)

  def flow(assigns) do
    ~H"""
      <%= if child = Fabric.get_current_child(@fabric) do %>
        <.live_child {Map.from_struct(child)} />
      <% end %>
    """
  end

  attr(:fabric, :map, required: true)
  attr(:gap, :string, default: "gap-4")

  def stack(assigns) do
    ~H"""
      <%= if children = Map.get(@fabric, :children) do %>
        <div class={"w-full h-full flex flex-col #{@gap}"}>
          <%= for child <- children do %>
            <.live_child {Map.from_struct(child)} />
          <% end %>
        </div>
      <% end %>
    """
  end

  attr(:ref, :map, required: true)
  attr(:params, :map, required: true)

  def live_child(assigns) do
    ~H"""
    <.live_component {Map.from_struct(@ref)} {@params}/>
    """
  end
end
