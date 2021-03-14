defmodule Core.Authorization.Node do
  @moduledoc """
  An authorization node represents a context where principals can gain
  additional roles. They can be nested to create a tree structure.
  """
  use Ecto.Schema

  schema "authorization_nodes" do
    belongs_to(:parent, Core.Authorization.Node)
    has_many(:role_assignments, Core.Authorization.RoleAssignment)
    timestamps()
  end
end
