defmodule Core.Studies.StudyPublic do
  @moduledoc """
  The study type.
  """
  use Timex

  alias Core.Marks
  alias Core.ImageHelpers
  alias Core.Studies
  alias Core.Studies.Study
  alias Core.SurveyTools
  alias Core.Themes
  require Core.Themes
  use Core.Themes

  defstruct [
    # Study
    study_id: nil,
    title: "",
    # Survey
    survey_tool_id: nil,
    subtitle: "",
    expectations: "",
    description: "",
    survey_url: "",
    subject_count: 0,
    duration: "",
    phone_enabled: true,
    tablet_enabled: true,
    desktop_enabled: true,
    banner_photo_url: "",
    banner_title: "",
    banner_subtitle: "",
    banner_url: "",
    # Transient
    image_info: nil,
    themes: "",
    byline: "",
    icon_url: "",
    highlights: [],
    organisation_name: "",
    organisation_icon: "",
    devices: []
  ]

  @study_fields ~w(title)a
  @survey_tool_fields ~w(subtitle expectations description survey_url subject_count duration phone_enabled tablet_enabled desktop_enabled banner_photo_url banner_title banner_subtitle banner_url)a

  def create(study, survey_tool) do
    study_opts =
      study
      |> Map.take(@study_fields)
      |> Map.put(:study_id, study.id)

    survey_tool_opts =
      survey_tool
      |> Map.take(@survey_tool_fields)
      |> Map.put(:survey_tool_id, survey_tool.id)

    transient_opts = %{
      image_info: ImageHelpers.get_image_info(survey_tool.image_id, 2560, 1920),
      themes: get_themes(survey_tool),
      byline: get_byline(study, survey_tool),
      organisation_icon: get_organisation_id(survey_tool),
      organisation_name: get_organisation_name(survey_tool),
      devices: get_devices(survey_tool_opts),
      highlights: get_highlights(survey_tool)
    }

    opts =
      %{}
      |> Map.merge(study_opts)
      |> Map.merge(survey_tool_opts)
      |> Map.merge(transient_opts)

    struct!(Core.Studies.StudyPublic, opts)
  end

  def get_devices(survey_tool) do
    [:desktop, :phone, :tablet]
    |> Enum.filter(&survey_tool[String.to_atom("#{&1}_enabled")])
  end

  def get_byline(%Study{} = study, _survey_tool) do
    authors =
      study
      |> Studies.list_authors()
      |> Enum.map(& &1.fullname)
      |> Enum.join(", ")

    "#{dgettext("eyra-survey", "by.author.label")}: " <> authors
  end

  defp get_organisation_name(survey_tool) do
    case get_organisation_id(survey_tool) do
      nil ->
        nil

      id ->
        organisation =
          Marks.instances()
          |> Enum.find(&(&1.id === String.to_existing_atom(id)))

        organisation.label
    end
  end

  defp get_organisation_id(%{marks: [first_mark | _]}), do: first_mark
  defp get_organisation_id(_), do: nil

  def get_highlights(survey_tool) do
    reward_string =
      CurrencyFormatter.format(
        survey_tool.reward_value,
        survey_tool.reward_currency,
        keep_decimals: true
      )

    occupied_spot_count = SurveyTools.count_tasks(survey_tool, [:pending, :completed])
    open_spot_count = survey_tool.subject_count - occupied_spot_count
    open_spot_string = "Nog #{open_spot_count} van #{survey_tool.subject_count}"

    available_title = dgettext("eyra-survey", "available.highlight.title")
    reward_title = dgettext("eyra-survey", "reward.highlight.title")
    duration_title = dgettext("eyra-survey", "duration.highlight.title")
    spots_title = dgettext("eyra-survey", "spots.highlight.title")

    available_text =
      dgettext("eyra-survey", "available.future.highlight.text",
        from: "15 apr",
        till: "22 april 2021"
      )

    duration_text =
      dgettext("eyra-survey", "duration.highlight.text", duration: survey_tool.duration)

    [
      %{title: available_title, text: available_text},
      %{title: reward_title, text: reward_string},
      %{title: duration_title, text: duration_text},
      %{title: spots_title, text: open_spot_string}
    ]

    # %{title: duration_title, text: "± #{survey_tool.duration} minuten"},
  end

  def get_themes(survey_tool) do
    survey_tool.themes
    |> Themes.labels()
    |> Enum.filter(& &1.active)
    |> Enum.map(& &1.value)
    |> Enum.join(", ")
  end
end
