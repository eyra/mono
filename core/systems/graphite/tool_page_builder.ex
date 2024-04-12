defmodule Systems.Graphite.ToolPageBuilder do
  use CoreWeb, :verified_routes
  import CoreWeb.Gettext
  alias CoreWeb.UI.Timestamp
  alias ExAws.S3

  alias Systems.{
    Graphite
  }

  def view_model(
        %{
          status: status,
          title: title,
          expectations: expectations,
          data_set: data_set,
          template_repo: template_repo
        } = tool,
        %{spot_id: spot_id}
      ) do
    active? = status == :online
    highlights = highlights(tool)

    {:ok, presigned_data_set} =
      ExAws.Config.new(:s3)
      |> S3.presigned_url(:get, bucket(), data_set, [])

    dataset_button =
      if active? do
        %{
          action: %{type: :http_get, to: presigned_data_set, target: "_blank"},
          face: %{type: :primary, label: dgettext("eyra-graphite", "dataset.button")}
        }
      else
        nil
      end

    template_button = %{
      action: %{type: :http_get, to: template_repo, target: "_blank"},
      face: %{type: :link, text: dgettext("eyra-graphite", "template.button"), font: ""}
    }

    title =
      if title == nil do
        dgettext("eyra-ui", "title.placeholder")
      else
        title
      end

    spot_form = %{
      id: :spot_form,
      module: Graphite.SpotForm,
      spot_id: spot_id
    }

    submission_list_form = %{
      id: :submission_list_form,
      module: Graphite.SubmissionListForm,
      spot_id: spot_id,
      active?: active?
    }

    # TODO: Is this used for anything?
    leaderboard = nil

    %{
      hero_title: dgettext("eyra-graphite", "tool.page.title"),
      title: title,
      highlights: highlights,
      expectations: expectations,
      dataset_button: dataset_button,
      template_button: template_button,
      spot_form: spot_form,
      submission_list_form: submission_list_form,
      leaderboard: leaderboard
    }
  end

  defp bucket do
    :core
    |> Application.fetch_env!(:s3)
    |> Keyword.fetch!(:bucket)
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
      title: dgettext("eyra-graphite", "highlight.submissions.title"),
      text: "#{submission_count}"
    }
  end

  def highlight(%{spots: spots}, :spot_count) do
    %{title: dgettext("eyra-graphite", "highlight.spots.title"), text: "#{Enum.count(spots)}"}
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
    title = dgettext("eyra-graphite", "highlight.deadline.title")
    text = dngettext("eyra-graphite", "1 day", "%{count} days", max(0, days_to_go))

    %{title: title, text: text}
  end

  defp submission_count(%{submissions: submissions}), do: Enum.count(submissions)
end
