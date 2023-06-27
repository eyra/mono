defmodule Systems.Benchmark.SubmissionView do
  use CoreWeb, :html

  attr(:items, :list, required: true)

  def list(assigns) do
    ~H"""
      <%= if Enum.count(@items) > 0 do %>
        <table>
          <tbody>
          <%= for item <- @items do %>
            <.item {item} />
          <% end %>
          </tbody>
        </table>
      <% end %>
    """
  end

  attr(:description, :string, required: true)
  attr(:team, :string, default: nil)
  attr(:summary, :string, required: true)
  attr(:url, :string, required: true)
  attr(:buttons, :list, required: true)

  def item(assigns) do
    ~H"""
    <tr class="h-12">
      <%= if @team do %>
      <td class="pl-0">
        <Text.body_medium><%= @team %></Text.body_medium>
      </td>
      <% end %>
      <td class={if @team do "pl-8" else "pl-0" end}>
       <Text.body_medium><%= @description %></Text.body_medium>
      </td>
      <td class="pl-8">
        <Text.body_medium><%= @summary %></Text.body_medium>
      </td>
      <td class="pl-8">
        <Text.body_medium>
          <a class="text-primary underline" target="_blank" href={@url}>Github</a>
        </Text.body_medium>
      </td>
      <td class="pl-12">
        <div class="flex flex-row gap-4">
          <%= for button <- @buttons do %>
            <Button.dynamic {button} />
          <% end %>
        </div>
      </td>
    </tr>
    """
  end
end
