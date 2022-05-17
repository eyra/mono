defmodule Systems.Assignment.ExperimentModel do
  @moduledoc """
  The survey tool schema.
  """
  use Ecto.Schema
  use Frameworks.Utility.Model

  require Core.Enums.Devices

  import CoreWeb.Gettext
  import Ecto.Changeset

  alias Systems.{
    Survey,
    Lab
  }

  schema "experiments" do
    belongs_to(:auth_node, Core.Authorization.Node)

    belongs_to(:survey_tool, Systems.Survey.ToolModel)
    belongs_to(:lab_tool, Systems.Lab.ToolModel)

    field(:subject_count, :integer)
    field(:duration, :string)
    field(:language, :string)
    field(:devices, {:array, Ecto.Enum}, values: Core.Enums.Devices.schema_values())
    field(:ethical_approval, :boolean)
    field(:ethical_code, :string)

    field(:director, Ecto.Enum, values: [:campaign, :assignment])

    timestamps()
  end

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(experiment), do: experiment.auth_node_id
  end

  @operational_fields ~w(subject_count duration ethical_code ethical_approval devices)a
  @fields @operational_fields ++ ~w(language)a

  @required_fields ~w()a

  @impl true
  def operational_fields, do: @operational_fields

  @impl true
  def operational_validation(changeset) do
    validate_true(changeset, :ethical_approval)
  end

  defp validate_true(changeset, field) do
    case get_field(changeset, field) do
      true -> changeset
      _ -> add_error(changeset, field, "is not true")
    end
  end

  def changeset(tool, :auto_save, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def changeset(tool, _, params) do
    tool
    |> cast(params, [:director])
    |> cast(params, @fields)
  end

  def languages(%{language: language}) when not is_nil(language), do: [language]
  def languages(_), do: []

  def devices(%{devices: devices}) when not is_nil(devices), do: devices
  def devices(_), do: []

  def spot_count(%{subject_count: subject_count}) when not is_nil(subject_count),
    do: subject_count

  def spot_count(_), do: 0

  def duration(%{duration: duration}) when not is_nil(duration) do
    case Integer.parse(duration) do
      :error -> 0
      {duration, _} -> duration
    end
  end

  def duration(_), do: 0

  def apply_label(%{survey_tool: tool}) when not is_nil(tool),
    do: dgettext("link-survey", "apply.cta.title")

  def apply_label(%{lab_tool: tool}) when not is_nil(tool),
    do: dgettext("link-lab", "apply.cta.title")

  def apply_label(_), do: "<apply>"

  def open_label(%{survey_tool: tool}) when not is_nil(tool),
    do: dgettext("link-survey", "open.cta.title")

  def open_label(%{lab_tool: tool}) when not is_nil(tool),
    do: dgettext("link-lab", "open.cta.title")

  def open_label(_), do: "<open>"

  def ready?(%{survey_tool: tool}) when not is_nil(tool), do: Systems.Survey.Context.ready?(tool)
  def ready?(%{lab_tool: tool}) when not is_nil(tool), do: Systems.Lab.Context.ready?(tool)

  def external_path(%{survey_tool: survey_tool}, panl_id) do
    Survey.ToolModel.external_path(survey_tool, panl_id)
  end

  def external_path(_, _), do: nil

  def tool_id(%{survey_tool_id: tool_id}) when not is_nil(tool_id), do: tool_id
  def tool_id(%{lab_tool_id: tool_id}) when not is_nil(tool_id), do: tool_id

  def tool_form(%{survey_tool_id: tool_id}) when not is_nil(tool_id), do: Survey.ToolForm
  def tool_form(%{lab_tool_id: tool_id}) when not is_nil(tool_id), do: Lab.ToolForm

  def tool_field(%Survey.ToolModel{}), do: :survey_tool
  def tool_field(%Lab.ToolModel{}), do: :lab_tool

  def tool_id_field(%Survey.ToolModel{}), do: :survey_tool_id
  def tool_id_field(%Lab.ToolModel{}), do: :lab_tool_id
end
