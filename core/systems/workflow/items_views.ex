defmodule Systems.Workflow.ItemViews do
  use CoreWeb, :html

  alias Systems.Workflow
  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Align

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:items, :list, required: true)

  def library(assigns) do
    ~H"""
    <div class="w-full h-full bg-grey5">
      <Text.title2><%= @title %></Text.title2>
      <Text.body><%= @description %></Text.body>
      <.spacing value="M" />
      <div class="flex flex-col gap-4">
        <%= for item <- @items do %>
          <.library_item {item} />
        <% end %>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:description, :string, required: true)

  def library_item(assigns) do
    ~H"""
    <div class="w-full h-full">
      <Panel.flat bg_color="bg-white">
        <Text.title4><%= @title %></Text.title4>
        <.spacing value="XS" />
        <Text.body><%= @description %></Text.body>
        <.spacing value="M" />
        <.wrap>
          <Button.dynamic
            face={%{type: :primary, bg_color: "bg-success", label: dgettext("eyra-workflow", "add.to.button") }}
            action={%{type: :send, event: "add", item: @id}}
          />
        </.wrap>
      </Panel.flat>
    </div>
    """
  end

  defp relative_position(0, _count), do: :top
  defp relative_position(position, count) when position == count - 1, do: :bottom
  defp relative_position(_position, _count), do: :middle

  attr(:items, :list, required: true)
  attr(:types, :list, required: true)
  attr(:user, :map, required: true)
  attr(:uri_origin, :string, required: true)
  attr(:ordering_enabled?, :boolean, default: false)
  attr(:parent, :map, required: true)

  def list(assigns) do
    ~H"""
    <div class="bg-grey5 rounded-2xl p-6 flex flex-col gap-4">
      <%= if @ordering_enabled? do %>
        <Align.horizontal_center>
          <Text.hint><%= dgettext("eyra-workflow", "item.list.hint") %></Text.hint>
        </Align.horizontal_center>
      <% end %>
      <%= for {item, index} <- Enum.with_index(@items) do %>
        <.live_component
          id={"item-cell-#{item.id}"}
          module={Workflow.ItemCell}
          type={Enum.at(@types, index)}
          item={item}
          user={@user}
          uri_origin={@uri_origin}
          parent={@parent}
          relative_position={relative_position(item.position, Enum.count(@items))}
          ordering_enabled?={@ordering_enabled?}
        />
      <% end %>
    </div>
    """
  end

  attr(:title, :string, default: nil)
  slot(:inner_block, default: nil)

  def collapsed(assigns) do
    ~H"""
    <div>
      <%= if @title do %>
        <Text.title6><%= @title %></Text.title6>
        <.spacing value="M" />
      <% end %>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
