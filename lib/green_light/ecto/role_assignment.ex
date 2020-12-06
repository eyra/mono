defmodule GreenLight.Ecto.RoleAssignment do
  @moduledoc """
  A role assignment entity is used to assign a role to a principal on a
  specific entity.
  """

  defmacro green_light_role_assignment_fields(roles) do
    quote do
      field :entity_id, :integer, primary_key: true
      field :entity_type, :string, primary_key: true
      field :principal_id, :integer, primary_key: true

      field :role, Ecto.Enum,
        primary_key: true,
        values: unquote(roles) |> MapSet.to_list()
    end
  end

  defmacro __using__(_) do
    quote do
      import Ecto.Changeset

      @doc false
      def changeset(role_assignment, attrs) do
        role_assignment
        |> cast(attrs, [:entity_id, :entity_type, :role, :principal_id])
        |> validate_required([:entity_id, :entity_type, :role, :principal_id])
      end

      import unquote(__MODULE__), only: [green_light_role_assignment_fields: 1]
    end
  end
end
