defmodule LinkWeb.Study.New do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  use EyraUI.Create, :study
  alias Surface.Components.Form
  alias EyraUI.Form.{TextInput}
  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Button.{SubmitButton, SecondaryLiveViewButton}
  alias EyraUI.Container.{ContentArea}

  alias Link.Studies
  alias Link.SurveyTools

  @impl true
  def create(socket, changeset) do
    current_user = socket.assigns.current_user

    # temp ensure every study has at least one survey
    with {:ok, study} <- Studies.create_study(changeset, current_user),
         {:ok, _author} <- Studies.add_author(study, current_user),
         {:ok, _survey_tool} <-
           SurveyTools.create_survey_tool(create_survey_tool_attrs(study.title), study) do
      {:ok, Routes.live_path(socket, LinkWeb.Study.Edit, study.id)}
    end
  end

  def create_survey_tool_attrs(title) do
    %{title: title, phone_enabled: true, tablet_enabled: true, desktop_enabled: true}
  end

  defdelegate get_changeset(attrs \\ %{}), to: Studies, as: :get_study_changeset

  def handle_event("cancel", _params, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, LinkWeb.Dashboard))}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("eyra-study", "study.new.title") }} />
      <ContentArea>
        <Form for={{ @changeset }} submit="create">
          <TextInput field={{:title}} label_text={{dgettext("eyra-study", "title.label")}} />
          <SubmitButton label={{ dgettext("eyra-study", "save.button") }} />
          <SecondaryLiveViewButton label={{ dgettext("eyra-ux", "cancel.button") }} event="cancel" />
        </Form>
      </ContentArea>
    """
  end
end
