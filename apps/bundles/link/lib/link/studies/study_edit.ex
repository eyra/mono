defmodule Link.Studies.StudyEdit do
  @moduledoc """
  The study type.
  """
  use Ecto.Schema
  use Timex

  import Ecto.Changeset
  import EctoCommons.URLValidator
  import LinkWeb.Gettext

  alias EyraUI.Timestamp
  alias Link.SurveyTools
  alias Link.SurveyTools.SurveyTool

  embedded_schema do
    field(:study_id, :integer)
    field(:title, :string)
    field(:byline, :string)
    field(:survey_tool_id, :integer)
    field(:description, :string)
    field(:survey_url, :string)
    field(:subject_count, :integer)
    field(:subject_pending_count, :integer)
    field(:subject_completed_count, :integer)
    field(:subject_vacant_count, :integer)
    field(:duration, :string)
    field(:phone_enabled, :boolean, default: true)
    field(:tablet_enabled, :boolean, default: true)
    field(:desktop_enabled, :boolean, default: true)
    field(:published_at, :naive_datetime)
    field(:is_published, :boolean)
  end

  @required_fields ~w(title byline)a
  @required_fields_for_publish ~w(title byline survey_url subject_count)a

  @transient_fields ~w(byline is_published subject_pending_count subject_completed_count subject_vacant_count)a
  @study_fields ~w(title)a
  @survey_tool_fields ~w(description survey_url subject_count duration phone_enabled tablet_enabled desktop_enabled published_at)a

  @fields @study_fields ++ @survey_tool_fields ++ @transient_fields

  @doc false
  def changeset(study_edit, params) do
    study_edit
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> validate_optional_url(:survey_url)
    |> validate_optional_number(:subject_count, greater_than: 0)
  end

  def validate_for_publish(study_edit, params) do
    study_edit
    |> cast(params, @fields)
    |> validate_required(@required_fields_for_publish)
    |> validate_url(:survey_url)
    |> validate_number(:subject_count, greater_than: 0)
  end

  def validate_optional_url(changeset, field) do
    if blank?(changeset, field) do
      changeset
    else
      changeset |> validate_url(field)
    end
  end

  def validate_optional_number(changeset, field, opts) do
    if blank?(changeset, field) do
      changeset
    else
      changeset |> validate_number(field, opts)
    end
  end

  defp blank?(changeset, field) do
    %{changes: changes} = changeset
    value = Map.get(changes, field)
    blank?(value)
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

    subject_pending_count = SurveyTools.count_pending_tasks(survey_tool)
    subject_completed_count = SurveyTools.count_completed_tasks(survey_tool)

    subject_vacant_count =
      case survey_tool.subject_count do
        count when is_nil(count) -> 0
        count when count > 0 -> count - (subject_completed_count + subject_pending_count)
        _ -> 0
      end

    transient_opts =
      %{}
      |> Map.put(:byline, get_byline(survey_tool))
      |> Map.put(:is_published, SurveyTool.published?(survey_tool))
      |> Map.put(:subject_pending_count, subject_pending_count)
      |> Map.put(:subject_completed_count, subject_completed_count)
      |> Map.put(:subject_vacant_count, subject_vacant_count)

    opts =
      %{}
      |> Map.merge(study_opts)
      |> Map.merge(survey_tool_opts)
      |> Map.merge(transient_opts)

    struct(Link.Studies.StudyEdit, opts)
  end

  def get_byline(%SurveyTool{} = survey_tool) do
    if SurveyTool.published?(survey_tool) do
      label = dgettext("eyra-survey", "published.true.label")
      timestamp = Timestamp.humanize(survey_tool.published_at)
      "#{label}: #{timestamp}"
    else
      label = dgettext("eyra-survey", "created.label")
      timestamp = Timestamp.humanize(survey_tool.inserted_at)
      "#{label}: #{timestamp}"
    end
  end
end
