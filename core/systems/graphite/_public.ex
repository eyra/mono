defmodule Systems.Graphite.Public do
  import Ecto.Query, warn: false

  alias CoreWeb.UI.Timestamp
  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo

  alias Systems.Graphite

  # FIXME: should come from CMS
  # @main_category "f1_score"
  @main_category "aap"

  def update(%Graphite.LeaderboardModel{} = leaderboard, attrs) do
    Graphite.LeaderboardModel.changeset(leaderboard, attrs)
    |> Repo.update!()
  end

  def get_tool!(id, preload \\ []) do
    from(tool in Graphite.ToolModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_submission!(id, preload \\ []) do
    from(submission in Graphite.SubmissionModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def set_tool_status(%Graphite.ToolModel{} = tool, status) do
    tool
    |> Graphite.ToolModel.changeset(%{status: status})
    |> Repo.update!()
  end

  def set_tool_status(id, status) do
    get_tool!(id)
    |> set_tool_status(status)
  end

  def prepare_tool(%{} = attrs, auth_node \\ Core.Authorization.prepare_node()) do
    attrs = Map.put(attrs, :status, :concept)

    %Graphite.ToolModel{}
    |> Graphite.ToolModel.changeset(attrs)
    |> Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_leaderboard(%{} = attrs) do
    %Graphite.LeaderboardModel{}
    |> Graphite.LeaderboardModel.changeset(attrs)
  end

  def create_submission(%Changeset{} = changeset) do
    changeset
    |> Repo.insert(
      conflict_target: [:id],
      on_conflict: :replace_all
    )
  end

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
      score =
        case Float.parse(value) do
          {score, ""} -> score
          _ -> 0
        end

      %{
        name: metric,
        score: score
      }
    end)
  end

  def get_leaderboard!(id, preload \\ []) do
    Repo.get!(Graphite.LeaderboardModel, id) |> Repo.preload(preload)
  end

  # These are no longer being used
  # def import_csv_lines(tool, auth_node, board_name, csv_lines, metrics) do
  #   Multi.new()
  #   |> Multi.run(:auth_node, fn _, _ -> {:ok, auth_node} end)
  #   |> Multi.run(:version, fn _, _ -> {:ok, "102"} end)
  #   |> prepare_leaderboard(board_name, metrics)
  #   |> find_submissions(csv_lines)
  #   |> prepare_score_lines(csv_lines, metrics, board_name)
  #   |> Repo.transaction()
  # end

  # defp find_submissions(multi, csv_lines) do
  #   csv_lines
  #   |> Enum.reduce(
  #     multi,
  #     fn line, multi ->
  #       Multi.run(multi, {:submission, line["submission"]}, fn _ ->
  #         {:ok, Graphite.Public.get_submission!(line["submission"])}
  #       end)
  #     end
  #   )
  # end

  # FIXME: remove
  # TMP function
  defp prepare_submissions(multi, tool, csv_lines, description \\ "Method X") do
    csv_lines
    |> Enum.with_index()
    |> Enum.reduce(
      multi,
      fn {_line, idx}, multi ->
        Multi.insert(multi, {:submission, idx}, fn %{:auth_node => auth_node} ->
          %Graphite.SubmissionModel{}
          |> Graphite.SubmissionModel.change(%{
            auth_node_id: auth_node.id,
            description: description,
            tool_id: tool.id,
            github_commit_url:
              "https://github.com/eyra/mono/commit/9d10bd2907dda135ebe86511489570dbf8c067c0"
          })
        end)
      end
    )
  end

  defp prepare_score_lines(multi, csv_lines, metrics, board_name) do
    csv_lines
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {line, idx}, multi ->
      prepare_scores(multi, line, idx, metrics, board_name)
    end)
  end

  defp prepare_scores(multi, line, idx, metrics, board_name) do
    Enum.reduce(metrics, multi, fn metric, multi ->
      prepare_score(multi, metric, line, idx, board_name)
    end)
  end

  defp prepare_score(multi, metric, line, idx, board_name) do
    Multi.insert(multi, {:score, idx, metric}, fn %{
                                                    {:submission, ^idx} => submission,
                                                    {:leaderboard, ^board_name} => board
                                                  } ->
      %Graphite.ScoreModel{}
      |> Graphite.ScoreModel.changeset(%{
        metric: metric,
        score: line[metric],
        leaderboard_id: board.id,
        submission_id: submission.id
      })
    end)
  end

  def import_csv_lines(csv_lines) do
    csv_lines
    |> Enum.filter(&(Map.get(&1, "status") == "success"))
    |> Enum.map(&parse_entry/1)
    |> Graphite.Public.import_entries()
  end

  def import_csv_lines(leaderboard, lines) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Multi.new()
    |> Multi.insert_all(
      :add_scores,
      Graphite.ScoreModel,
      Enum.flat_map(
        lines,
        fn line -> create_scores(line, leaderboard, now) end
      ),
      returning: true
    )
    |> update_leaderboard_generation_date(leaderboard, now)
    |> Repo.transaction()
  end

  defp create_scores(line, leaderboard, now) do
    leaderboard.metrics
    |> Enum.map(fn metric ->
      %{
        metric: metric,
        score: String.to_float(line[metric]),
        leaderboard_id: leaderboard.id,
        submission_id: String.to_integer(line["submission"]),
        inserted_at: now,
        updated_at: now
      }
    end)
  end

  defp update_leaderboard_generation_date(multi, leaderboard, datetime) do
    changeset = Graphite.LeaderboardModel.changeset(leaderboard, %{generation_date: datetime})
    Multi.update(multi, :leaderboard, changeset)
  end

  def import_entries(entries) when is_list(entries) do
    names =
      entries
      |> List.first(%{scores: []})
      |> Map.get(:scores)
      |> Enum.map(& &1.name)

    Multi.new()
    |> prepare_leaderboards(names)
    |> prepare_leaderboard_entries(entries)
    |> Repo.transaction()
  end

  defp prepare_leaderboards(multi, []), do: multi

  defp prepare_leaderboards(multi, names) when is_list(names) do
    date = Timestamp.format_user_input_date(Timestamp.now())

    multi =
      Multi.run(multi, :version, fn _, _ ->
        count = Graphite.Public.count_leaderboard_versions()
        {:ok, "#{date}_#{count + 1}"}
      end)

    Enum.reduce(names, multi, &prepare_leaderboard(&2, &1))
  end

  defp prepare_leaderboard(multi, name, metrics \\ []) when is_binary(name) do
    Multi.insert(multi, {:leaderboard, name}, fn %{version: version} ->
      %Graphite.LeaderboardModel{}
      |> Graphite.LeaderboardModel.changeset(%{name: name, version: version, metrics: metrics})
    end)
  end

  defp prepare_leaderboard_entries(multi, entries) when is_list(entries) do
    Enum.reduce(entries, multi, &prepare_leaderboard_entry(&2, &1))
  end

  defp prepare_leaderboard_entry(multi, %{submission_id: submission_id, scores: scores})
       when is_list(scores) do
    prepare_scores(multi, scores, submission_id)
  end

  defp prepare_scores(multi, scores, submission_id) when is_list(scores) do
    Enum.reduce(scores, multi, &prepare_score(&2, &1, submission_id))
  end

  defp prepare_score(multi, %{name: name, score: score}, submission_id) do
    Multi.insert(multi, {:score, "#{name}-#{submission_id}"}, fn %{
                                                                   {:leaderboard, ^name} =>
                                                                     leaderboard
                                                                 } ->
      submission = get_submission!(submission_id)

      %Graphite.ScoreModel{}
      |> Graphite.ScoreModel.changeset(%{score: score})
      |> Ecto.Changeset.put_assoc(:leaderboard, leaderboard)
      |> Ecto.Changeset.put_assoc(:submission, submission)
    end)
  end

  def list_submissions(tool_id, preload \\ []) do
    from(submission in Graphite.SubmissionModel,
      where: submission.tool_id == ^tool_id,
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_leaderboard_categories(tool_id, preload \\ []) do
    max_version =
      from(leaderboard in Graphite.LeaderboardModel,
        where: leaderboard.tool_id == ^tool_id,
        select: max(leaderboard.version)
      )
      |> Repo.one()

    if max_version do
      from(leaderboard in Graphite.LeaderboardModel,
        where: leaderboard.tool_id == ^tool_id,
        where: leaderboard.version == ^max_version,
        preload: ^preload
      )
      |> Repo.all()
      |> Enum.sort(&sort_categories/2)
    else
      []
    end
  end

  defp sort_categories(%{name: @main_category}, _), do: true
  defp sort_categories(_, _), do: false

  def count_leaderboard_versions() do
    list =
      from(leaderboard in Graphite.LeaderboardModel,
        group_by: leaderboard.version,
        distinct: leaderboard.version,
        select: count("*")
      )
      |> Repo.all()

    Enum.count(list)
  end

  def delete(%Graphite.SubmissionModel{} = submission) do
    Repo.delete(submission)
  end
end
