defmodule Systems.Campaign.MonitorTableView do
  use CoreWeb.UI.Component

  alias Systems.{
    Crew
  }

  alias Frameworks.Pixel.Text.{Title6}

  prop(columns, :list, required: true)
  prop(tasks, :list, required: true)

  defp padding(0), do: "pl-0"
  defp padding(_), do: "pl-8"

  @impl true
  def render(assigns) do
    ~F"""
      <table>
        <thead>
          <tr class="text-left">
            <th :for={{column, index} <- Enum.with_index(@columns)} class={"#{padding(index)}"} >
              <Title6>{column}</Title6>
            </th>
          </tr>
        </thead>
        <tbody>
          <Crew.TaskItemView :for={task <- @tasks} {...task} />
        </tbody>
      </table>
    """
  end
end
