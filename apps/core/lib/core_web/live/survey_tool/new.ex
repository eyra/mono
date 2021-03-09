defmodule CoreWeb.SurveyTool.New do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  alias Surface.Components.Form
  alias EyraUI.Form.{TextInput}

  alias Core.SurveyTools
  alias Core.SurveyTools.SurveyTool

  data(changeset, :any)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> setup_changeset}
  end

  @impl true
  def handle_event("create", %{"survey_tool" => data}, socket) do
    [study | _] = Core.Repo.all(Core.Studies.Study)

    case SurveyTools.create_survey_tool(data, study) do
      {:ok, _} ->
        {:noreply,
         push_redirect(socket,
           to: Routes.live_path(socket, CoreWeb.SurveyTool.Index),
           replace: true
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <h1>Edit Survey tool</h1>
    <Form for={{ @changeset }} submit="create">
      <TextInput field={{:title}} label_text={{dgettext("eyra-account", "title.label")}} />
      <TextInput field={{:survey_url}} label_text={{dgettext("eyra-account", "survey_url.label")}} />
      <button>Create</button>
    </Form>
    <span><Surface.Components.Link to={{ Routes.live_path(@socket, CoreWeb.SurveyTool.Index) }} >Back</Surface.Components.Link></span>
    """
  end

  defp setup_changeset(socket) do
    socket |> assign(changeset: SurveyTools.change_survey_tool(%SurveyTool{}))
  end
end
