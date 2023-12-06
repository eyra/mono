defmodule Systems.Benchmark.ToolModel do
  @moduledoc """
  The benchmark tool schema.
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import CoreWeb.Gettext

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
    field(:director, Ecto.Enum, values: [:project, :assignment])
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

  defimpl Frameworks.Concept.Directable do
    def director(%{director: director}), do: Frameworks.Concept.System.director(director)
  end

  def ready?(tool) do
    changeset =
      changeset(tool, %{})
      |> validate()

    changeset.valid?()
  end

  defimpl Frameworks.Concept.ToolModel do
    alias Systems.Benchmark
    def key(_), do: :benchmark
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: dgettext("eyra-benchmark", "apply.cta.title")
    def open_label(_), do: dgettext("eyra-benchmark", "open.cta.title")
    def ready?(tool), do: Benchmark.ToolModel.ready?(tool)
    def form(_), do: Benchmark.Form
    def launcher(_), do: nil

    def task_labels(_) do
      %{
        pending: dgettext("eyra-benchmark", "pending.label"),
        participated: dgettext("eyra-benchmark", "participated.label")
      }
    end

    def attention_list_enabled?(_t), do: false
    def group_enabled?(_t), do: true
  end
end
