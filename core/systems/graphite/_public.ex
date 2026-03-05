defmodule Systems.Graphite.Public do
  @moduledoc false
  use Core, :public

  import Ecto.Query, warn: false
  import Systems.Graphite.Queries

  alias Core.Repo
  alias Ecto.Changeset
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Systems.Assignment
  alias Systems.Graphite
  alias Systems.Workflow

  def get_challenge(%Graphite.LeaderboardModel{tool: tool}, preload \\ []) do
    Assignment.Public.get_by_tool(tool, preload)
  end

  def get_leaderboard!(id, preload \\ []) do
    Repo.get!(from(leaderboard in Graphite.LeaderboardModel, preload: ^preload), id)
  end

  def get_leaderboard_by_tool(%Graphite.ToolModel{} = tool, preload \\ []) do
    tool
    |> leaderboard_query()
    |> Repo.one()
    |> Repo.preload(preload)
  end

  def list_leaderboards(%Assignment.Model{special: :benchmark_challenge, workflow: workflow}, preload \\ []) do
    workflow
    |> Workflow.Public.list_tools(:submit)
    |> leaderboards_by_tools()
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def get_tool!(id, preload \\ []) do
    Repo.get!(from(tool in Graphite.ToolModel, preload: ^preload), id)
  end

  def get_submission(id) do
    Repo.one(from(submission in Graphite.SubmissionModel, where: submission.id == ^id))
  end

  def get_submission!(id, preload \\ []) do
    Repo.get!(from(submission in Graphite.SubmissionModel, preload: ^preload), id)
  end

  def get_submission(tool, user, role, preload \\ []) do
    submissions =
      {tool, user, role}
      |> submission_query()
      |> Repo.all()
      |> Repo.preload(preload)

    List.first(submissions)
  end

  def get_submissions(%Graphite.ToolModel{} = tool) do
    tool
    |> Graphite.Queries.submission_query()
    |> Repo.all()
  end

  def get_submission_count(tool) do
    tool
    |> Graphite.Queries.submission_query()
    |> Repo.aggregate(:count)
  end

  def get_participants(%Graphite.LeaderboardModel{} = leaderboard) do
    leaderboard
    |> submission_query()
    |> participants_by_submissions()
    |> Repo.all()
  end

  def set_tool_status(%Graphite.ToolModel{} = tool, status) do
    tool
    |> Graphite.ToolModel.changeset(%{status: status})
    |> Repo.update!()
  end

  def set_tool_status(id, status) do
    id
    |> get_tool!()
    |> set_tool_status(status)
  end

  def prepare_leaderboard(attrs, auth_node \\ auth_module().prepare_node()) do
    %Graphite.LeaderboardModel{}
    |> Graphite.LeaderboardModel.changeset(attrs)
    |> Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_tool(%{} = attrs, auth_node \\ auth_module().prepare_node()) do
    %Graphite.ToolModel{}
    |> Graphite.ToolModel.changeset(attrs)
    |> Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_submission(%{} = attrs, user, tool) do
    auth_node = auth_module().prepare_node(user, :owner)

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
    |> Repo.commit()
  end

  def update_leaderboard(leaderboard, attrs) do
    Multi.new()
    |> Multi.update(:graphite_leaderboard, fn _ ->
      Graphite.LeaderboardModel.changeset(leaderboard, attrs)
    end)
    |> Repo.commit()
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
      submission
      |> Graphite.SubmissionModel.change(attrs)
      |> Graphite.SubmissionModel.validate()
    end)
    |> Signal.Public.multi_dispatch({:graphite_submission, :updated})
    |> Repo.commit()
  end

  def list_submissions(struct, preload \\ [])

  def list_submissions(%Graphite.ToolModel{} = tool, preload) do
    tool
    |> submission_query()
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_submissions(%Graphite.LeaderboardModel{} = leaderboard, preload) do
    leaderboard
    |> submission_query()
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def import_scores(leaderboard, %Graphite.ScoresParseResult{success: {valid_records, _}}) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    scores_to_delete = score_query(leaderboard)

    leaderboard_changeset = Graphite.LeaderboardModel.changeset(leaderboard, %{generation_date: now})

    Multi.new()
    |> Multi.delete_all(:delete_scores, scores_to_delete)
    |> Multi.insert_all(
      :add_scores,
      Graphite.ScoreModel,
      Enum.flat_map(
        valid_records,
        fn {_, record, _} -> create_scores(record, leaderboard, now) end
      ),
      returning: true
    )
    |> Multi.update(:graphite_leaderboard, leaderboard_changeset)
    |> Signal.Public.multi_dispatch({:graphite_leaderboard, :updated})
    |> Repo.commit()
  end

  defp create_scores(line, leaderboard, datetime) do
    Enum.map(leaderboard.metrics, fn metric ->
      %{
        metric: metric,
        score: line[metric],
        leaderboard_id: leaderboard.id,
        submission_id: line["submission-id"],
        inserted_at: datetime,
        updated_at: datetime
      }
    end)
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
    tool_id
    |> Graphite.Public.get_tool!()
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

defimpl Core.Persister, for: Systems.Graphite.LeaderboardModel do
  def save(_leaderboard, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :graphite_leaderboard) do
      {:ok, %{graphite_leaderboard: graphite_leaderboard}} -> {:ok, graphite_leaderboard}
      _ -> {:error, changeset}
    end
  end
end
