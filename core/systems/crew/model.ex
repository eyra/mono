defmodule Systems.Crew.Model do
  @moduledoc """
  The schema for a group of participants with (assigned) tasks
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "crews" do
    field(:reference_type, Ecto.Enum, values: [:campaign])
    field(:reference_id, :integer)

    has_many(:tasks, Systems.Crew.TaskModel, foreign_key: :crew_id)
    has_many(:members, Systems.Crew.MemberModel, foreign_key: :crew_id)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @fields ~w(reference_type reference_id)a

  defimpl GreenLight.AuthorizationNode do
    def id(crew), do: crew.auth_node_id
  end

  @doc false
  def changeset(crew, attrs \\ %{}) do
    crew
    |> cast(attrs, @fields)
  end
end
