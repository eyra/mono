defmodule Systems.Benchmark.Public do
  import Ecto.Query, warn: false

  alias CoreWeb.UI.Timestamp
  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo

  alias Systems.Benchmark

  # FIXME: should come from CMS
  @main_category "f1_score"

  def get_tool!(id, preload \\ []) do
    from(tool in Benchmark.ToolModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_submission!(id, preload \\ []) do
    from(submission in Benchmark.SubmissionModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def set_tool_status(%Benchmark.ToolModel{} = tool, status) do
    tool
    |> Benchmark.ToolModel.changeset(%{status: status})
    |> Repo.update!()
  end

  def set_tool_status(id, status) do
    get_tool!(id)
    |> set_tool_status(status)
  end

  def prepare_tool(%{} = attrs, auth_node \\ Core.Authorization.prepare_node()) do
    attrs = Map.put(attrs, :status, :concept)

    %Benchmark.ToolModel{}
    |> Benchmark.ToolModel.changeset(attrs)
    |> Changeset.put_assoc(:auth_node, auth_node)
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

  def import_csv_lines(csv_lines) do
    csv_lines
    |> Enum.filter(&(Map.get(&1, "status") == "success"))
    |> Enum.map(&parse_entry/1)
    |> Benchmark.Public.import_entries()
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
        count = Benchmark.Public.count_leaderboard_versions()
        {:ok, "#{date}_#{count + 1}"}
      end)

    Enum.reduce(names, multi, &prepare_leaderboard(&2, &1))
  end

  defp prepare_leaderboard(multi, name) when is_binary(name) do
    Multi.insert(multi, {:leaderboard, name}, fn %{version: version} ->
      %Benchmark.LeaderboardModel{}
      |> Benchmark.LeaderboardModel.changeset(%{name: name, version: version})
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

      %Benchmark.ScoreModel{}
      |> Benchmark.ScoreModel.changeset(%{score: score})
      |> Ecto.Changeset.put_assoc(:leaderboard, leaderboard)
      |> Ecto.Changeset.put_assoc(:submission, submission)
    end)
  end

  def list_submissions(tool_id, preload \\ []) do
    from(submission in Benchmark.SubmissionModel,
      where: submission.tool_id == ^tool_id,
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_leaderboard_categories(tool_id, preload \\ []) do
    max_version =
      from(leaderboard in Benchmark.LeaderboardModel,
        where: leaderboard.tool_id == ^tool_id,
        select: max(leaderboard.version)
      )
      |> Repo.one()

    if max_version do
      from(leaderboard in Benchmark.LeaderboardModel,
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
      from(leaderboard in Benchmark.LeaderboardModel,
        group_by: leaderboard.version,
        distinct: leaderboard.version,
        select: count("*")
      )
      |> Repo.all()

    Enum.count(list)
  end

  def delete(%Benchmark.SubmissionModel{} = submission) do
    Repo.delete(submission)
  end
end
