defmodule LinkWeb.Study.Show do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  use EyraUI.AutoSave, :study_show
  alias Surface.Components.Form
  alias EyraUI.Form.{TextInput, UrlInput, NumberInput, TextArea, Checkbox}
  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.{Title1, Title3}

  alias Link.Studies
  alias Link.Studies.{Study, StudyShow}
  alias Link.SurveyTools

  @impl true
  def load(%{"id" => id}, _session, _socket) do
    study = Studies.get_study!(id)
    study_survey = study |> load_survey_tool()
    StudyShow.create(study, study_survey)
  end

  def load_survey_tool(%Study{} = study) do
    case study |> Studies.list_survey_tools() do
      [survey_tool] -> survey_tool
      [survey_tool | _] -> survey_tool
      _ -> raise "Expected at least one survey tool for study #{study.title}"
    end
  end

  @impl true
  def get_changeset(study_show, attrs \\ %{}) do
    study_show |> StudyShow.changeset(attrs)
  end

  @impl true
  def save(changeset) do
    if changeset.valid? do
      save_valid(changeset)
    else
      changeset = %{changeset | action: :save}
      {:error, changeset}
    end
  end

  def save_valid(changeset) do
    study_show = Ecto.Changeset.apply_changes(changeset)
    study_attrs = StudyShow.to_study(study_show)
    survey_tool_attrs = StudyShow.to_survey_tool(study_show)

    study = Studies.get_study!(study_show.study_id)

    study
    |> load_survey_tool()
    |> SurveyTools.update_survey_tool(survey_tool_attrs)

    study
    |> Studies.update_study(study_attrs)

    {:ok, study_show}
  end

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Studies.get_study!(id)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("eyra-study", "study.show.title") }} />
      <ContentArea>
        <Title1>{{ @study_show.title }}</Title1>
        <Form for={{ @changeset }} change="save">
          <TextInput field={{:title}} label_text={{dgettext("eyra-study", "title.label")}} />
          <TextInput field={{:description}} label_text={{dgettext("eyra-study", "description.label")}} />
          <Title3>{{dgettext("eyra-survey", "config.title")}}</Title3>
          <UrlInput field={{:url}} label_text={{dgettext("eyra-survey", "config.url.label")}} />
          <NumberInput field={{:nrofsubjects}} label_text={{dgettext("eyra-survey", "config.nrofsubjects.label")}} />
          <Title3>{{dgettext("eyra-survey", "config.devices.title")}}</Title3>
          <Checkbox field={{:mobile_enabled}} label_text={{dgettext("eyra-survey", "mobile.enabled.label")}}/>
          <Checkbox field={{:tablet_enabled}} label_text={{dgettext("eyra-survey", "tablet.enabled.label")}}/>
          <Checkbox field={{:desktop_enabled}} label_text={{dgettext("eyra-survey", "desktop.enabled.label")}}/>
          <Title3>{{dgettext("eyra-survey", "info.title")}}</Title3>
          <TextArea field={{:info}} label_text={{dgettext("eyra-survey", "info.label")}}/>
        </Form>
      </ContentArea>
    """
  end
end
