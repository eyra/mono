defmodule Systems.Graphite.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Core.Accounts.User
  alias Systems.Graphite
  alias Systems.Assignment

  # Leaderboards

  def leaderboard_query() do
    from(Graphite.LeaderboardModel, as: :leaderboard)
  end

  def leaderboard_query(%Graphite.ToolModel{id: id}) do
    build(leaderboard_query(), :leaderboard, [
      tool_id == ^id
    ])
  end

  # Scores
  def score_query() do
    from(Graphite.ScoreModel, as: :score)
  end

  def score_query(%Graphite.LeaderboardModel{id: id}) do
    build(score_query(), :score, [
      leaderboard_id == ^id
    ])
  end

  def score_ids(selector) do
    score_query(selector)
    |> select([score: s], s.id)
    |> distinct(true)
  end

  # Submissions

  def submission_query() do
    from(Graphite.SubmissionModel, as: :submission)
  end

  def submission_query(%Graphite.ToolModel{id: id}) do
    build(submission_query(), :submission, [
      tool_id == ^id
    ])
  end

  def submission_query({%Graphite.ToolModel{} = tool, user_ref, role}) do
    user_id = User.user_id(user_ref)

    build(submission_query(tool), :submission,
      auth_node: [
        role_assignments: [
          role == ^role,
          principal_id == ^user_id
        ]
      ]
    )
  end

  def submission_query(%Graphite.LeaderboardModel{tool_id: id}) do
    build(submission_query(), :submission, [
      tool_id == ^id
    ])
  end

  def submission_query(%Graphite.LeaderboardModel{} = leaderboard, user_ref, role) do
    user_id = User.user_id(user_ref)

    build(submission_query(leaderboard), :submission,
      auth_node: [
        role_assignments: [
          role == ^role,
          principal_id == ^user_id
        ]
      ]
    )
  end

  def submissions_by_pattern(field, pattern) when is_atom(field) and is_binary(pattern) do
    submission_query()
    |> where([submission: s], like(field(s, ^field), ^pattern))
  end

  def submissions_by_prefix(field, prefix) when is_atom(field) and is_binary(prefix) do
    submissions_by_pattern(field, "#{prefix}-%")
  end

  def submission_ids(selector) do
    submission_query(selector)
    |> select([submission: s], s.id)
    |> distinct(true)
  end

  # Tools

  def tool_query() do
    from(Graphite.ToolModel, as: :tool)
  end

  def tool_query(%Assignment.Model{id: id}) do
    build(tool_query(), :tool,
      tool_ref: [
        workflow_item: [
          workflow: [
            assignment: [
              id == ^id
            ]
          ]
        ]
      ]
    )
  end

  def tool_ids(selector) do
    tool_query(selector)
    |> select([tool: t], t.id)
    |> distinct(true)
  end

  # Participants

  def participant_query() do
    from(User, as: :participant)
  end

  def participants_by_submissions(%Ecto.Query{} = submissions) do
    principal_ids =
      build(submissions, :submission,
        auth_node: [
          role_assignments: []
        ]
      )
      |> select([role_assignments: ra], ra.principal_id)
      |> distinct(true)

    build(participant_query(), :participant, [
      id in subquery(principal_ids)
    ])
  end
end
