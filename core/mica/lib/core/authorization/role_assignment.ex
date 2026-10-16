defmodule Core.Authorization.RoleAssignment do
  @moduledoc """
  A role assignment entity is used to assign a role to a principal on a
  specific entity.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "authorization_role_assignments" do
    belongs_to(:node, Core.Authorization.Node)
    field(:principal_id, :integer, primary_key: true)

    field(:role, Ecto.Enum,
      primary_key: true,
      values: [:owner, :member, :creator, :participant, :tester]
    )

    timestamps()
  end

  @fields ~w(role principal_id)a

  def create(principal_id, role \\ :owner) do
    %__MODULE__{
      principal_id: principal_id,
      role: role
    }
  end

  def changeset(role_assignment, attrs) do
    role_assignment
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
