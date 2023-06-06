defmodule Systems.DataDonation.ToolModel do
  @moduledoc """
  The data donation tool schema.
  """
  use Ecto.Schema
  use Frameworks.Utility.Model

  require Core.Enums.Themes

  import Ecto.Changeset

  alias Systems.{
    DataDonation
  }

  require DataDonation.Platforms

  schema "data_donation_tools" do
    field(:platforms, {:array, Ecto.Enum}, values: DataDonation.Platforms.schema_values())
    field(:subject_count, :integer, default: 0)
    field(:director, Ecto.Enum, values: [:project])
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @fields ~w(platforms subject_count director)a
  @required_fields ~w()a

  @impl true
  def operational_fields, do: @fields

  @impl true
  def operational_validation(changeset), do: changeset

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(tool), do: tool.auth_node_id
  end

  def changeset(tool, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  # def validate_optional_number(changeset, field, opts) do
  #   if blank?(changeset, field) do
  #     changeset
  #   else
  #     changeset |> validate_number(field, opts)
  #   end
  # end

  # defp blank?(changeset, field) do
  #   %{changes: changes} = changeset
  #   value = Map.get(changes, field)
  #   blank?(value)
  # end
end
