defmodule Link.Authorization.RoleAssignment do
  use Ecto.Schema

  schema "authorization_role_assignments" do
    belongs_to :node, Link.Authorization.Node
    field :principal_id, :integer, primary_key: true

    field :role, Ecto.Enum,
      primary_key: true,
      values: [:owner, :researcher]

    timestamps()
  end
end
