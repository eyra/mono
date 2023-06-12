defmodule Systems.Project.ToolRefModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  schema "tool_refs" do
    belongs_to(:survey_tool, Systems.Survey.ToolModel)
    belongs_to(:lab_tool, Systems.Lab.ToolModel)
    belongs_to(:data_donation_tool, Systems.DataDonation.ToolModel)
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

  def preload_graph(:full),
    do:
      preload_graph([
        :survey_tool,
        :lab_tool,
        :data_donation_tool
      ])

  def preload_graph(:survey_tool), do: [sursurvey_toolvey: []]
  def preload_graph(:lab_tool), do: [lab_tool: [:time_slots]]
  def preload_graph(:data_donation_tool), do: [data_donation_tool: []]
end
