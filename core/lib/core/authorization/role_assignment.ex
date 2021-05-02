defmodule Core.Authorization.RoleAssignment do
  @moduledoc """
  A role assignment entity is used to assign a role to a principal on a
  specific entity.
  """
  use Ecto.Schema

  schema "authorization_role_assignments" do
    belongs_to(:node, Core.Authorization.Node)
    field(:principal_id, :integer, primary_key: true)

    field(:role, Ecto.Enum,
      primary_key: true,
      values: [:owner, :researcher, :participant]
    )

    timestamps()
  end
end
