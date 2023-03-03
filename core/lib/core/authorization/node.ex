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

  def create() do
    %__MODULE__{}
  end

  def create(%Core.Authorization.Node{id: id}) do
    %__MODULE__{
      parent_id: id
    }
  end

  def create(principal_id, role) do
    %__MODULE__{
      role_assignments: [Core.Authorization.RoleAssignment.create(principal_id, role)]
    }
  end
end
