defmodule Link.Studies.StudyShow do
  @moduledoc """
  The study type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :study_id, :integer
    field :title, :string
    field :survey_tool_id, :integer
    field :description, :string
    field :survey_url, :string
    field :subject_count, :integer
    field :phone_enabled, :boolean
    field :tablet_enabled, :boolean
    field :desktop_enabled, :boolean
  end

  @required_fields ~w(title)a

  @study_fields ~w(title)a
  @survey_tool_fields ~w(description survey_url subject_count phone_enabled tablet_enabled desktop_enabled)a
  @fields @study_fields ++ @survey_tool_fields

  @doc false
  def changeset(study_show, params) do
    study_show
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  @spec to_study(map) :: map
  def to_study(study_show) do
    study_show
    |> Map.take(@study_fields)
  end

  @spec to_survey_tool(map) :: map
  def to_survey_tool(study_show) do
    study_show
    |> Map.take(@survey_tool_fields)
  end

  def create(study, survey_tool) do
    study_opts =
      study
      |> Map.take(@study_fields)
      |> Map.put(:study_id, study.id)

    survey_tool_opts =
      survey_tool
      |> Map.take(@survey_tool_fields)

    struct(Link.Studies.StudyShow, Map.merge(study_opts, survey_tool_opts))
  end
end
