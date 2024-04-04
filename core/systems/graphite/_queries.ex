defmodule Systems.Graphite.Queries do
  @moduledoc """
  Queries in this module support the following options:
  - :locked, :boolean, default: false
  """

  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Core.Accounts.User
  alias Systems.Graphite
  alias Systems.Assignment

  # Submissions

  def submission_query() do
    from(Graphite.SubmissionModel, as: :submission)
  end

  def submission_query(opts) do
    locked = Keyword.get(opts, :locked, false)

    build(submission_query(), :submission, [
      locked == ^locked
    ])
  end

  def submission_query(%Graphite.ToolModel{id: id}, opts) do
    build(submission_query(opts), :submission, [
      tool_id == ^id
    ])
  end

  def submission_query({%Graphite.ToolModel{} = tool, user_ref, role}, opts) do
    user_id = User.user_id(user_ref)

    build(submission_query(tool, opts), :submission,
      auth_node: [
        role_assignments: [
          role == ^role,
          principal_id == ^user_id
        ]
      ]
    )
  end

  def submission_ids(selector, opts) do
    submission_query(selector, opts)
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
end
