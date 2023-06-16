defmodule Systems.Project.ToolRefModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Project,
    Survey,
    Lab,
    DataDonation,
    Benchmark
  }

  schema "tool_refs" do
    has_one(:item, Project.ItemModel, foreign_key: :tool_ref_id)
    belongs_to(:survey_tool, Survey.ToolModel)
    belongs_to(:lab_tool, Lab.ToolModel)
    belongs_to(:data_donation_tool, DataDonation.ToolModel)
    belongs_to(:benchmark_tool, Benchmark.ToolModel)
    timestamps()
  end

  @required_fields ~w()a
  @fields @required_fields

  @doc false
  def changeset(tool_ref, attrs) do
    tool_ref
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :survey_tool,
        :lab_tool,
        :data_donation_tool,
        :benchmark_tool
      ])

  def preload_graph(:survey_tool), do: [survey_tool: Survey.ToolModel.preload_graph(:full)]
  def preload_graph(:lab_tool), do: [lab_tool: Lab.ToolModel.preload_graph(:full)]

  def preload_graph(:data_donation_tool),
    do: [data_donation_tool: DataDonation.ToolModel.preload_graph(:full)]

  def preload_graph(:benchmark_tool),
    do: [benchmark_tool: Benchmark.ToolModel.preload_graph(:down)]
end
