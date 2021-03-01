defmodule GreenLight.Ecto.RoleAssignment do
  @moduledoc """
  A role assignment entity is used to assign a role to a principal on a
  specific entity.
  """

  defmacro green_light_role_assignment_fields(roles) do
    quote do
      field(:node_id, :integer, primary_key: true)
      field(:principal_id, :integer, primary_key: true)

      field(:role, Ecto.Enum,
        primary_key: true,
        values: unquote(roles) |> MapSet.to_list()
      )
    end
  end

  defmacro __using__(_) do
    quote do
      import Ecto.Changeset

      @doc false
      def changeset(role_assignment, attrs) do
        role_assignment
        |> cast(attrs, [:node_id, :role, :principal_id])
        |> validate_required([:node_id, :role, :principal_id])
      end

      import unquote(__MODULE__), only: [green_light_role_assignment_fields: 1]
    end
  end
end
