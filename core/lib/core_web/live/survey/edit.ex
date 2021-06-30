defmodule CoreWeb.Survey.Edit do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  alias Surface.Components.Form
  alias EyraUI.Form.{TextInput}
  use EyraUI.AutoSave, :survey_tool

  alias Core.Survey.Tools

  @impl true
  def init(_params, _session, socket) do
    socket
  end

  @impl true
  def load(%{"id" => id}, _session, _socket) do
    Tools.get_survey_tool!(id)
  end

  @impl true
  defdelegate get_changeset(survey_tool, type, attrs \\ %{}),
    to: Tools,
    as: :change_survey_tool

  @impl true
  defdelegate save(changeset), to: Tools, as: :update_survey_tool

  def render(assigns) do
    ~H"""
    <h1>Edit Survey tool</h1>
    <Form for={{ @changeset }} change="save">
      <TextInput field={{:title}} label_text={{dgettext("eyra-account", "title.label")}} />
      <TextInput field={{:survey_url}} label_text={{dgettext("eyra-account", "survey_url.label")}} />
    </Form>
    <span><Surface.Components.Link to={{ Routes.live_path(@socket, CoreWeb.Survey.Index) }} >Back</Surface.Components.Link></span>
    """
  end
end
