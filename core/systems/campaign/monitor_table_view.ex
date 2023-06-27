defmodule Systems.Campaign.MonitorTableView do
  use CoreWeb, :html

  alias Systems.{
    Crew
  }

  import Crew.TaskItemView

  defp padding(0), do: "pl-0"
  defp padding(_), do: "pl-8"

  attr(:columns, :list, required: true)
  attr(:tasks, :list, required: true)

  def monitor_table_view(assigns) do
    ~H"""
    <table>
      <thead>
        <tr class="text-left">
          <%= for {column, index} <- Enum.with_index(@columns) do %>
            <th class={"#{padding(index)}"}>
              <Text.title6><%= column %></Text.title6>
            </th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <%= for task <- @tasks do %>
          <.task_item_view {task} />
        <% end %>
      </tbody>
    </table>
    """
  end
end
