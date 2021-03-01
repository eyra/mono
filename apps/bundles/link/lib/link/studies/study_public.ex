defmodule Link.Studies.StudyPublic do
  @moduledoc """
  The study type.
  """
  use Ecto.Schema
  use Timex

  alias EyraUI.Timestamp
  alias Link.Studies
  alias Link.Studies.Study
  alias Link.SurveyTools.SurveyTool
  import LinkWeb.Gettext

  embedded_schema do
    field(:study_id, :integer)
    field(:title, :string)
    field(:byline, :string)
    field(:survey_tool_id, :integer)
    field(:description, :string)
    field(:survey_url, :string)
    field(:subject_count, :integer)
    field(:duration, :string)
    field(:phone_enabled, :boolean, default: true)
    field(:tablet_enabled, :boolean, default: true)
    field(:desktop_enabled, :boolean, default: true)
  end

  @study_fields ~w(title)a
  @survey_tool_fields ~w(description survey_url subject_count duration phone_enabled tablet_enabled desktop_enabled)a

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
      |> Map.put(:byline, get_byline(study, survey_tool))

    opts =
      %{}
      |> Map.merge(study_opts)
      |> Map.merge(survey_tool_opts)
      |> Map.merge(transient_opts)

    struct(Link.Studies.StudyPublic, opts)
  end

  def get_byline(%Study{} = study, %SurveyTool{} = survey_tool) do
    date =
      if SurveyTool.published?(survey_tool) do
        timestamp = Timestamp.humanize(survey_tool.published_at)
        "#{dgettext("eyra-survey", "published.true.label")}: #{timestamp}"
      else
        timestamp = Timestamp.humanize(survey_tool.inserted_at)
        "#{dgettext("eyra-survey", "created.label")}: #{timestamp}"
      end

    authors =
      study
      |> Studies.list_authors()
      |> Enum.map(& &1.fullname)
      |> Enum.join(", ")

    date <> " - #{dgettext("eyra-survey", "by.author.label")} " <> authors
  end
end
