defmodule Link.Users.RoleAssignment do
  @moduledoc """
  The role assignment for the Link application.
  """
  use Ecto.Schema
  use GreenLight.Ecto.RoleAssignment

  @primary_key false
  schema "role_assignments" do
    green_light_role_assignment_fields(Link.Authorization.possible_roles())
    timestamps()
  end
end
