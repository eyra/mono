defmodule Systems.Graphite.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Graphite
  alias Core.Accounts.User

  def submission_query() do
    from(Graphite.SubmissionModel, as: :submission)
  end

  def submission_query(%Graphite.ToolModel{id: tool_id}, user_ref, role) do
    user_id = User.user_id(user_ref)

    build(submission_query(), :submission, [
      tool_id == ^tool_id,
      auth_node: [
        role_assignments: [
          role == ^role,
          principal_id == ^user_id
        ]
      ]
    ])
  end
end
