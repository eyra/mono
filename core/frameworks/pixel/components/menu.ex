defmodule Frameworks.Pixel.Menu do
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Button

  attr(:home, :map, default: nil)
  attr(:primary, :map, default: nil)
  attr(:secondary, :map, default: nil)
  attr(:align, :string, default: "items-left")

  def generic(assigns) do
    ~H"""
    <div class="h-full">
      <div class={"flex flex-col h-full #{@align}"}>
        <%= if @home do %>
          <div class="flex-wrap">
            <.home {@home} />
          </div>
        <% end %>
        <%= if @primary do %>
          <div class="flex-wrap">
            <.stack items={@primary} />
          </div>
        <% end %>
        <%= if @secondary do %>
          <div class="flex-grow">
          </div>
          <div class="flex-wrap">
            <.stack items={@secondary} />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:menu_id, :string, required: true)
  attr(:action, :map, required: true)
  attr(:face, :map, required: true)

  def home(assigns) do
    ~H"""
      <div class="mb-8">
        <.item {assigns} />
      </div>
    """
  end

  attr(:items, :list, default: nil)

  def stack(%{items: nil} = _assigns), do: nil

  def stack(assigns) do
    ~H"""
      <%= for item <- @items do %>
        <div class="mb-2">
          <.item {item} />
        </div>
      <% end %>
    """
  end

  attr(:id, :string, required: true)
  attr(:menu_id, :string, required: true)
  attr(:overlay?, :boolean, default: false)
  attr(:action, :map, required: true)
  attr(:face, :map, required: true)

  def item(assigns) do
    ~H"""
    <Button.menu id={"#{@menu_id}_#{@id}"} overlay?={@overlay?} action={@action} face={@face} />
    """
  end
end
