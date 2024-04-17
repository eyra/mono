defmodule Systems.Graphite.Public do
  import Ecto.Query, warn: false
  import Systems.Graphite.Queries

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo

  alias Frameworks.Signal
  alias Systems.Graphite

  def get_leaderboard!(id, preload \\ []) do
    from(leaderboard in Graphite.LeaderboardModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_tool!(id, preload \\ []) do
    from(tool in Graphite.ToolModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_submission(id) do
    from(submission in Graphite.SubmissionModel,
      where: submission.id == ^id
    )
    |> Repo.one()
  end

  def get_submission!(id, preload \\ []) do
    from(submission in Graphite.SubmissionModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_submission(tool, user, role, preload \\ []) do
    submissions =
      submission_query({tool, user, role})
      |> Repo.all()
      |> Repo.preload(preload)

    List.first(submissions)
  end

  def get_submissions(%Graphite.ToolModel{} = tool) do
    Graphite.Queries.submission_query(tool)
    |> Repo.all()
  end

  def get_submission_count(tool) do
    Graphite.Queries.submission_query(tool)
    |> Repo.aggregate(:count)
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
    |> Multi.run(:open_for_submissions?, fn _, _ ->
      if open_for_submissions?(tool) do
        {:ok, true}
      else
        {:error, false}
      end
    end)
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
    |> Multi.run(:can_update?, fn _, _ ->
      if can_update?(submission) do
        {:ok, true}
      else
        {:error, false}
      end
    end)
    |> Multi.update(:graphite_submission, fn _ ->
      Graphite.SubmissionModel.change(submission, attrs)
      |> Graphite.SubmissionModel.validate()
    end)
    |> Signal.Public.multi_dispatch({:graphite_submission, :updated})
    |> Repo.transaction()
  end

  def list_submissions(struct, preload \\ [])

  def list_submissions(%Graphite.ToolModel{} = tool, preload) do
    tool
    |> submission_query()
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_submissions(%Graphite.LeaderboardModel{} = leaderboard, preload) do
    submission_query(leaderboard)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def import_scores(leaderboard, %Graphite.ScoresParseResult{valid: valid_records}) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Multi.new()
    |> Multi.insert_all(
      :add_scores,
      Graphite.ScoreModel,
      Enum.flat_map(
        valid_records,
        fn {_, record, _} -> create_scores(record, leaderboard, now) end
      ),
      returning: true
    )
    |> update_leaderboard_generation_date(leaderboard, now)
    |> Repo.transaction()
  end

  defp create_scores(line, leaderboard, datetime) do
    leaderboard.metrics
    |> Enum.map(fn metric ->
      %{
        metric: metric,
        score: line[metric],
        leaderboard_id: leaderboard.id,
        submission_id: line["submission"],
        inserted_at: datetime,
        updated_at: datetime
      }
    end)
  end

  defp update_leaderboard_generation_date(multi, leaderboard, datetime) do
    changeset = Graphite.LeaderboardModel.changeset(leaderboard, %{generation_date: datetime})
    Multi.update(multi, :leaderboard_generation_date, changeset)
  end

  def delete(%Graphite.SubmissionModel{} = submission) do
    Repo.delete(submission)
  end

  def can_update?(%Graphite.SubmissionModel{tool_id: tool_id}) do
    open_for_submissions?(tool_id)
  end

  def open_for_submissions?(%Graphite.ToolModel{id: tool_id}) do
    open_for_submissions?(tool_id)
  end

  def open_for_submissions?(tool_id) do
    Graphite.Public.get_tool!(tool_id)
    |> Graphite.ToolModel.open_for_submissions?()
  end
end

defimpl Core.Persister, for: Systems.Graphite.ToolModel do
  def save(_tool, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :graphite_tool) do
      {:ok, %{graphite_tool: graphite_tool}} -> {:ok, graphite_tool}
      _ -> {:error, changeset}
    end
  end
end
