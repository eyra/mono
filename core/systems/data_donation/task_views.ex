defmodule Systems.DataDonation.TaskViews do
  use CoreWeb, :html

  alias Systems.DataDonation
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
            face={%{type: :primary, bg_color: "bg-success", label: "Add to list" }}
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

  attr(:tasks, :list, required: true)
  attr(:parent, :map, required: true)

  def list(assigns) do
    ~H"""
    <div class="bg-grey5 rounded-2xl p-6 flex flex-col gap-4">
      <Align.horizontal_center>
        <Text.hint><%= dgettext("eyra-data-donation", "task.list.hint") %></Text.hint>
      </Align.horizontal_center>
      <%= for task <- @tasks do %>
        <.live_component
          id={"task-cell-#{task.id}"}
          module={DataDonation.TaskCell}
          entity_id={task.id}
          parent={@parent}
          relative_position={relative_position(task.position, Enum.count(@tasks))}
        />
      <% end %>
    </div>
    """
  end
end
