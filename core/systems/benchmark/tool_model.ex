defmodule Systems.Benchmark.ToolModel do
  @moduledoc """
  The benchmark tool schema.
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Benchmark
  }

  schema "benchmark_tools" do
    field(:status, Ecto.Enum, values: Benchmark.ToolStatus.values())
    field(:title, :string)
    field(:expectations, :string)
    field(:data_set, :string)
    field(:template_repo, :string)
    field(:deadline, :string)
    field(:director, Ecto.Enum, values: [:project])
    belongs_to(:auth_node, Core.Authorization.Node)
    has_many(:spots, Benchmark.SpotModel, foreign_key: :tool_id)
    has_many(:leaderboards, Benchmark.LeaderboardModel, foreign_key: :tool_id)

    timestamps()
  end

  @fields ~w(status title expectations data_set template_repo deadline director)a
  @required_fields @fields

  def changeset(tool, params) do
    tool
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :auth_node,
        :spots,
        :leaderboards
      ])

  def preload_graph(:auth_node), do: [auth_node: []]
  def preload_graph(:spots), do: [spots: Benchmark.SpotModel.preload_graph(:down)]

  def preload_graph(:leaderboards),
    do: [leaderboards: Benchmark.LeaderboardModel.preload_graph(:down)]

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(tool), do: tool.auth_node_id
  end
end
