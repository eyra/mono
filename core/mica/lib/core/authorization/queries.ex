defmodule Core.Authorization.Queries do
  alias Core.Authorization
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Account

  def auth_node_query() do
    from(Authorization.Node, as: :auth_node)
  end

  def auth_node_query(%Account.User{id: user_id}, role) when is_atom(role) do
    build(auth_node_query(), :assignment,
      role_assignments: [
        role == ^role,
        principal_id == ^user_id
      ]
    )
  end
end
