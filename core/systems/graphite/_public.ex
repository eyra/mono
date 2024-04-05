defmodule Systems.Graphite.Public do
  import Ecto.Query, warn: false
  import Systems.Graphite.Queries

  alias CoreWeb.UI.Timestamp
  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo

  alias Frameworks.Signal
  alias Systems.Graphite

  # FIXME: should come from CMS
  @main_category "f1_score"

  def get_leaderboard!(id, preload \\ []) do
    from(leaderboard in Graphite.LeaderboardModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_tool!(id, preload \\ []) do
    from(tool in Graphite.ToolModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_submission!(id, preload \\ []) do
    from(submission in Graphite.SubmissionModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_submission(tool, user, role, preload \\ []) do
    submissions =
      submission_query(tool, user, role)
      |> Repo.all()
      |> Repo.preload(preload)

    List.first(submissions)
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

  def prepare_leaderboard(attrs, auth_node \\ Core.Authorization.prepare_node()) do
    %Graphite.LeaderboardModel{}
    |> Graphite.LeaderboardModel.changeset(attrs)
    |> Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_tool(%{} = attrs, auth_node \\ Core.Authorization.prepare_node()) do
    %Graphite.ToolModel{}
    |> Graphite.ToolModel.changeset(attrs)
    |> Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_submission(%{} = attrs, user, tool) do
    auth_node = Core.Authorization.prepare_node(user, :owner)

    %Graphite.SubmissionModel{}
    |> Graphite.SubmissionModel.change(attrs)
    |> Graphite.SubmissionModel.validate()
    |> Changeset.put_assoc(:tool, tool)
    |> Changeset.put_assoc(:auth_node, auth_node)
  end

  def add_submission(tool, user, attrs) do
    submission = prepare_submission(attrs, user, tool)

    Multi.new()
    |> Multi.insert(:graphite_submission, submission)
    |> Signal.Public.multi_dispatch({:graphite_submission, :inserted})
    |> Repo.transaction()
  end

  def update_leaderboard(leaderboard, attrs) do
    Multi.new()
    |> Multi.update(:graphite_leaderboard, fn _ ->
      Graphite.LeaderboardModel.changeset(leaderboard, attrs)
    end)
    |> Repo.transaction()
  end

  def update_submission(submission, attrs) do
    Multi.new()
    |> Multi.update(:graphite_submission, fn _ ->
      Graphite.SubmissionModel.change(submission, attrs)
      |> Graphite.SubmissionModel.validate()
    end)
    |> Signal.Public.multi_dispatch({:graphite_submission, :updated})
    |> Repo.transaction()
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

  def import_csv_lines(leaderboard, lines) do
    now = NaiveDateTime.utc_now()

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

  defp create_scores(line, leaderboard, dt) do
    leaderboard.metrics
    |> Enum.map(fn metric ->
      %{
        metric: metric,
        score: String.to_float(line[metric]),
        leaderboard_id: leaderboard.id,
        submission_id: String.to_integer(line["submission"]),
        inserted_at: dt,
        updated_at: dt
      }
    end)
  end

  defp update_leaderboard_generation_date(multi, leaderboard, dt) do
    changeset = Graphite.LeaderboardModel.changeset(leaderboard, %{generation_date: dt})
    Multi.update(multi, :leaderboard_generation_date, changeset)
  end

  def import_csv_lines(csv_lines) do
    csv_lines
    |> Enum.filter(&(Map.get(&1, "status") == "success"))
    |> Enum.map(&parse_entry/1)
    |> Graphite.Public.import_entries()
  end

  def import_entries(entries) when is_list(entries) do
    names =
      entries
      |> List.first(%{scores: []})
      |> Map.get(:scores)
      |> Enum.map(& &1.name)

    Multi.new()
    |> prepare_leaderboard_import(names)
    |> prepare_leaderboard_entries(entries)
    |> Repo.transaction()
  end

  defp prepare_leaderboard_import(multi, []), do: multi

  defp prepare_leaderboard_import(multi, names) when is_list(names) do
    date = Timestamp.format_user_input_date(Timestamp.now())

    multi =
      Multi.run(multi, :version, fn _, _ ->
        count = Graphite.Public.count_leaderboard_versions()
        {:ok, "#{date}_#{count + 1}"}
      end)

    Enum.reduce(names, multi, &prepare_leaderboard_import(&2, &1))
  end

  defp prepare_leaderboard_import(multi, name) when is_binary(name) do
    Multi.insert(multi, {:leaderboard, name}, fn %{version: version} ->
      %Graphite.LeaderboardModel{}
      |> Graphite.LeaderboardModel.changeset(%{name: name, version: version})
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
