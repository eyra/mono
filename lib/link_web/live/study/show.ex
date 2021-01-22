defmodule LinkWeb.Study.Show do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  use LinkWeb.LiveViewPowHelper
  use EyraUI.AutoSave, :study
  alias Surface.Components.Button
  alias Surface.Components.Form
  alias EyraUI.Form.{TextInput, Checkbox}
  alias EyraUI.Hero

  alias Link.Studies
  alias Link.Studies.Study

  def load(%{"id" => id}, session, socket) do
    Studies.get_study!(id)
  end

  defdelegate get_changeset(study, attrs \\ %{}), to: Studies, as: :change_study
  defdelegate save(changeset), to: Studies, as: :update_study

  def render(assigns) do
    ~H"""
      <Hero title={{ dgettext("eyra-study", "study.new.title") }}
            subtitle={{dgettext("eyra-study", "study.new.subtitle")}} />
    <Form for={{ @changeset }} change="save">
      <TextInput field={{:title}} label_text={{dgettext("eyra-study", "title.label")}} />
      <TextInput field={{:description}} label_text={{dgettext("eyra-study", "description.label")}} />
    </Form>
    """
  end

  defp setup_changeset(socket) do
    socket |> assign(changeset: Studies.change_survey_tool(%Study{}))
  end
end
