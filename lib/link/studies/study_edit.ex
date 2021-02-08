defmodule Link.Studies.StudyEdit do
  @moduledoc """
  The study type.
  """
  use Ecto.Schema
  use Timex
  import Ecto.Changeset

  alias EyraUI.Timestamp
  alias Link.SurveyTools.SurveyTool

  embedded_schema do
    field :study_id, :integer
    field :title, :string
    field :byline, :string
    field :survey_tool_id, :integer
    field :description, :string
    field :survey_url, :string
    field :subject_count, :integer
    field :duration, :string
    field :phone_enabled, :boolean, default: true
    field :tablet_enabled, :boolean, default: true
    field :desktop_enabled, :boolean, default: true
    field :is_published, :boolean
    field :published_at, :naive_datetime
  end

  @required_fields ~w(title byline)a

  @transient_fields ~w(byline)a
  @study_fields ~w(title)a
  @survey_tool_fields ~w(description survey_url subject_count duration phone_enabled tablet_enabled desktop_enabled is_published published_at)a

  @fields @study_fields ++ @survey_tool_fields ++ @transient_fields

  @doc false
  def changeset(study_edit, params) do
    study_edit
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def to_study(study_edit) do
    study_edit
    |> Map.take(@study_fields)
  end

  def to_survey_tool(study_edit) do
    study_edit
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
      |> Map.put(:survey_tool_id, survey_tool.id)

    transient_opts =
      %{}
      |> Map.put(:byline, get_byline(survey_tool))

    opts =
      %{}
      |> Map.merge(study_opts)
      |> Map.merge(survey_tool_opts)
      |> Map.merge(transient_opts)

    struct(Link.Studies.StudyEdit, opts)
  end

  def get_byline(%SurveyTool{} = survey_tool) do
    case survey_tool.is_published do
      true ->
        timestamp = Timestamp.humanize(survey_tool.published_at)
        "Gepubliseerd: #{timestamp}"

      _ ->
        timestamp = Timestamp.humanize(survey_tool.inserted_at)
        "Aangemaakt: #{timestamp}"
    end
  end
end
