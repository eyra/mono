defmodule Systems.Crew.Model do
  @moduledoc """
  The schema for a group of participants with (assigned) tasks
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Crew

  schema "crews" do
    has_many(:tasks, Systems.Crew.TaskModel, foreign_key: :crew_id)
    has_many(:members, Systems.Crew.MemberModel, foreign_key: :crew_id)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @fields ~w()a

  def auth_tree(%Crew.Model{auth_node: auth_node}), do: auth_node

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(crew), do: crew.auth_node_id
  end

  @doc false
  def changeset(crew, attrs \\ %{}) do
    crew
    |> cast(attrs, @fields)
  end
end
