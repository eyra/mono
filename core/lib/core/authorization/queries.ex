defmodule Core.Authorization.Queries do
  @moduledoc false
  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Core.Authorization
  alias Systems.Account

  require Ecto.Query
  require Frameworks.Utility.Query

  def auth_node_query do
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
