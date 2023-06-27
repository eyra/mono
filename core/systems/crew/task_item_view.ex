defmodule Systems.Crew.TaskItemView do
  use CoreWeb, :html

  defp message_color(%{type: :warning}), do: "text-grey1"
  defp message_color(%{type: :alarm}), do: "text-delete"
  defp message_color(_), do: "text-grey2"

  defp message_text(%{text: text}), do: "#{text}"
  defp message_text(_), do: ""

  attr(:public_id, :string, required: true)
  attr(:description, :string, default: nil)
  attr(:message, :map, default: nil)
  attr(:buttons, :list, default: [])

  def task_item_view(assigns) do
    ~H"""
    <tr class="h-12">
      <td class="pl-0 font-body text-bodymedium sm:text-bodylarge">
        Subject <%= @public_id %>
      </td>
      <%= if @description do %>
        <td class="pl-8 font-body text-bodysmall sm:text-bodymedium text-grey1">
          <%= @description %>
        </td>
      <% end %>
      <td class={"pl-8 font-body text-bodysmall sm:text-bodymedium #{message_color(@message)}"}>
        <%= message_text(@message) %>
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
