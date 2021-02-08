defmodule LinkWeb.Study.Edit do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  use LinkWeb.LiveViewPowHelper
  use EyraUI.AutoSave, :study_edit
  alias Surface.Components.Form
  alias EyraUI.Form.{TextInput, UrlInput, NumberInput, TextArea, Checkbox}
  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.{Title1, Title3, SubHead}
  alias EyraUI.Button.{PrimaryLiveViewButton, SecondaryLiveViewButton}
  alias EyraUI.Status.{Info, Warning}

  alias Link.Studies
  alias Link.Studies.{Study, StudyEdit}
  alias Link.SurveyTools

  @impl true
  def load(%{"id" => id}, _session, _socket) do
    study = Studies.get_study!(id)
    study_survey = study |> load_survey_tool()
    StudyEdit.create(study, study_survey)
  end

  def load_survey_tool(%Study{} = study) do
    case study |> Studies.list_survey_tools() do
      [survey_tool] -> survey_tool
      [survey_tool | _] -> survey_tool
      _ -> raise "Expected at least one survey tool for study #{study.title}"
    end
  end

  @impl true
  def get_changeset(study_edit, attrs \\ %{}) do
    study_edit |> StudyEdit.changeset(attrs)
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

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Studies.get_study!(id)
  end

  def save_valid(changeset) do
    study_edit = Ecto.Changeset.apply_changes(changeset)
    study_attrs = StudyEdit.to_study(study_edit)
    survey_tool_attrs = StudyEdit.to_survey_tool(study_edit)

    study = Studies.get_study!(study_edit.study_id)

    {:ok, survey_tool} =
      study
      |> load_survey_tool()
      |> SurveyTools.update_survey_tool(survey_tool_attrs)

    study
    |> Studies.update_study(study_attrs)

    study_edit = StudyEdit.create(study, survey_tool)

    {:ok, study_edit}
  end

  def handle_event("delete", _params, socket) do
    study_edit = socket.assigns[:study_edit]

    SurveyTools.get_survey_tool!(study_edit.survey_tool_id)
    |> SurveyTools.delete_survey_tool()

    Studies.get_study!(study_edit.study_id)
    |> Studies.delete_study()

    {:noreply, push_redirect(socket, to: Routes.live_path(socket, LinkWeb.Dashboard))}
  end

  def handle_event("publish", _params, socket) do
    params = %{is_published: true, published_at: NaiveDateTime.utc_now()}
    save(params, socket)
  end

  def handle_event("unpublish", _params, socket) do
    params = %{is_published: false, published_at: nil}
    save(params, socket)
  end

  def save(params, socket) do
    study_edit = socket.assigns[:study_edit]
    changeset = get_changeset(study_edit, params)
    {:ok, updated_study_edit} = save(changeset)

    socket =
      socket
      |> assign(
        study_edit: updated_study_edit,
        changeset: changeset,
        save_changeset: changeset
      )

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("eyra-study", "study.edit.title") }} />
      <ContentArea>
        <Info :if={{ @study_edit.is_published }} text="Gepubliceerd" />
        <Warning :if={{ !@study_edit.is_published }} text="Nog niet gepubliceerd" />
        <SubHead>{{ @study_edit.byline }}</SubHead>
        <Title1>{{ @study_edit.title }}</Title1>
        <Form for={{ @changeset }} change="save">
          <TextInput field={{:title}} label_text={{dgettext("eyra-study", "title.label")}} />
          <Title3>{{dgettext("eyra-survey", "config.title")}}</Title3>
          <UrlInput field={{:survey_url}} label_text={{dgettext("eyra-survey", "config.url.label")}} />
          <NumberInput field={{:subject_count}} label_text={{dgettext("eyra-survey", "config.nrofsubjects.label")}} />
          <Title3>{{dgettext("eyra-survey", "config.devices.title")}}</Title3>
          <Checkbox field={{:phone_enabled}} label_text={{dgettext("eyra-survey", "mobile.enabled.label")}}/>
          <Checkbox field={{:tablet_enabled}} label_text={{dgettext("eyra-survey", "tablet.enabled.label")}}/>
          <Checkbox field={{:desktop_enabled}} label_text={{dgettext("eyra-survey", "desktop.enabled.label")}}/>
          <Title3>{{dgettext("eyra-survey", "info.title")}}</Title3>
          <TextInput field={{:duration}} label_text={{dgettext("eyra-survey", "duration.label")}}/>
          <TextArea field={{:description}} label_text={{dgettext("eyra-survey", "info.label")}}/>
        </Form>
        <PrimaryLiveViewButton :if={{ !@study_edit.is_published }} label={{ dgettext("eyra-survey", "publish.button") }} event="publish" />
        <SecondaryLiveViewButton :if={{ @study_edit.is_published }} label={{ dgettext("eyra-survey", "unpublish.button") }} event="unpublish" />
        <SecondaryLiveViewButton :if={{ !@study_edit.is_published }} label={{ dgettext("eyra-survey", "delete.button") }} event="delete" />
      </ContentArea>
    """
  end
end
