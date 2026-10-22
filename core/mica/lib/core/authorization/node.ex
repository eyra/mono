defmodule Core.Authorization.Node do
  @moduledoc """
  An authorization node represents a context where principals can gain
  additional roles. They can be nested to create a tree structure.
  """
  use Ecto.Schema

  alias Ecto.Changeset

  schema "authorization_nodes" do
    belongs_to(:parent, __MODULE__)
    has_many(:children, __MODULE__, foreign_key: :parent_id, references: :id)

    has_many(:role_assignments, Core.Authorization.RoleAssignment)
    timestamps()
  end

  def change(node) do
    node
    |> Changeset.cast(%{}, [])
  end

  def create() do
    %__MODULE__{}
  end

  def create(%Core.Authorization.Node{id: id}) do
    %__MODULE__{
      parent_id: id
    }
  end

  def create([_ | _] = principal_ids, role) do
    role_assignments =
      Enum.map(principal_ids, &Core.Authorization.RoleAssignment.create(&1, role))

    %__MODULE__{
      role_assignments: role_assignments
    }
  end

  def create(principal_id, role), do: create([principal_id], role)
end
