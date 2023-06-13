defmodule Systems.Benchmark.ToolPageBuilder do
  import CoreWeb.Gettext
  alias CoreWeb.UI.Timestamp

  alias Systems.{
    Benchmark
  }

  def view_model(
        %{
          status: status,
          title: title,
          expectations: expectations,
          data_set: data_set
        } = tool,
        %{spot_id: spot_id}
      ) do
    active? = status == :online
    highlights = highlights(tool)

    download_dataset_button =
      if active? do
        %{
          action: %{type: :http_get, to: data_set, target: "_blank"},
          face: %{type: :primary, label: "Download"}
        }
      else
        nil
      end

    title =
      if title == nil do
        dgettext("eyra-ui", "title.placeholder")
      else
        title
      end

    spot_form = %{
      id: :spot_form,
      module: Benchmark.SpotForm,
      spot_id: spot_id
    }

    submission_list_form = %{
      id: :submission_list_form,
      module: Benchmark.SubmissionListForm,
      spot_id: spot_id,
      active?: active?
    }

    %{
      hero_title: dgettext("eyra-benchmark", "tool.page.title"),
      title: title,
      highlights: highlights,
      expectations: expectations,
      download_dataset_button: download_dataset_button,
      spot_form: spot_form,
      submission_list_form: submission_list_form
    }
  end

  defp highlights(tool) do
    [
      highlight(tool, :submissions),
      highlight(tool, :spot_count),
      highlight(tool, :deadline)
    ]
  end

  def highlight(%{spots: spots}, :submissions) do
    submission_count =
      spots
      |> Enum.map(&submission_count/1)
      |> Enum.reduce(0, fn count, acc -> acc + count end)

    %{
      title: dgettext("eyra-benchmark", "highlight.submissions.title"),
      text: "#{submission_count}"
    }
  end

  def highlight(%{spots: spots}, :spot_count) do
    %{title: dgettext("eyra-benchmark", "highlight.spots.title"), text: "#{Enum.count(spots)}"}
  end

  def highlight(%{deadline: nil}, :deadline) do
    highlight(0, :deadline)
  end

  def highlight(%{deadline: deadline}, :deadline) do
    deadline
    |> Timestamp.parse_user_input_date()
    |> Timestamp.days_until()
    |> highlight(:deadline)
  end

  def highlight(days_to_go, :deadline) when is_integer(days_to_go) do
    title = dgettext("eyra-benchmark", "highlight.deadline.title")
    text = dngettext("eyra-benchmark", "1 day", "%{count} days", max(0, days_to_go))

    %{title: title, text: text}
  end

  defp submission_count(%{submissions: submissions}), do: Enum.count(submissions)
end
