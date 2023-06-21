defmodule Systems.Benchmark.LeaderboardOverview do
  use CoreWeb, :live_component

  alias Systems.{
    Benchmark
  }

  import Benchmark.LeaderboardView

  @main_category "f1_score"

  @impl true
  def update(%{csv_lines: csv_lines}, %{assigns: %{entity: %{id: tool_id}}} = socket) do
    csv_lines
    |> Enum.filter(&(Map.get(&1, "status") == "success"))
    |> Enum.map(&parse_entry/1)
    |> Benchmark.Public.import(tool_id)

    {
      :ok,
      socket
      |> update_leaderboard()
    }
  end

  @impl true
  def update(%{id: id, entity: entity}, socket) do
    import_form = %{
      id: :import_form,
      module: Benchmark.ImportForm,
      parent: %{type: __MODULE__, id: id},
      placeholder: dgettext("eyra-benchmark", "csv-select-placeholder"),
      select_button: dgettext("eyra-benchmark", "csv-select-file-button"),
      replace_button: dgettext("eyra-benchmark", "csv-replace-file-button"),
      process_button: dgettext("eyra-benchmark", "csv-import-button")
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        import_form: import_form
      )
      |> update_leaderboard()
    }
  end

  defp update_leaderboard(%{assigns: %{entity: %{id: tool_id}}} = socket) do
    categories =
      Benchmark.Public.list_leaderboard_categories(tool_id, scores: [submission: [:spot]])
      |> Enum.sort(&sort_categories/2)

    leaderboard = %{categories: categories}

    assign(socket, leaderboard: leaderboard)
  end

  defp sort_categories(%{name: @main_category}, _), do: true
  defp sort_categories(_, _), do: false

  defp parse_entry(line) do
    {id, line} = Map.pop(line, "id")
    {status, line} = Map.pop(line, "status")
    {message, line} = Map.pop(line, "error_message")

    submission_id =
      id
      |> String.split(":")
      |> List.first()
      |> String.to_integer()

    %{
      submission_id: submission_id,
      status: status,
      message: message,
      scores: parse_scores(line)
    }
  end

  defp parse_scores(%{} = scores) do
    Enum.map(scores, fn {metric, value} ->
      %{
        name: metric,
        score: String.to_float(value)
      }
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-benchmark", "tabbar.item.leaderboard")%></Text.title2>
        <Text.title4><%= dgettext("eyra-benchmark", "import.leaderboard.title")%></Text.title4>
        <.spacing value="XS" />
        <.live_component {@import_form} />
        <.spacing value="XL" />
        <.leaderboard {@leaderboard} />
      </Area.content>
    </div>
    """
  end
end
