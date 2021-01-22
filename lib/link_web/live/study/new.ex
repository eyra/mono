defmodule LinkWeb.Study.New do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  use LinkWeb.LiveViewPowHelper
  use EyraUI.Create, :study
  alias Surface.Components.Button
  alias Surface.Components.Form
  alias EyraUI.Form.{TextInput, Checkbox}
  alias EyraUI.Hero

  alias Link.Studies
  alias Link.Studies.Study

  def mount(params, session, socket) do
    socket =
      socket |> assign(current_user: get_user(socket, session) |> IO.inspect(label: "USER"))

    super(params, session, socket)
  end

  def create(socket, changeset) do
    current_user = socket.assigns.current_user

    with {:ok, study} <- Studies.create_study(changeset, current_user) do
      {:ok, Routes.live_path(socket, LinkWeb.Study.Show, study.id)}
    end
  end

  defdelegate get_changeset(attrs \\ %{}), to: Studies, as: :get_study_changeset

  def render(assigns) do
    ~H"""
      <Hero title={{ dgettext("eyra-study", "study.new.title") }}
            subtitle={{dgettext("eyra-study", "study.new.subtitle")}} />
    <Form for={{ @changeset }} submit="create">
      <TextInput field={{:title}} label_text={{dgettext("eyra-study", "title.label")}} />
      <TextInput field={{:description}} label_text={{dgettext("eyra-study", "description.label")}} />
      <button>Create</button>
    </Form>
    """
  end

  defp setup_changeset(socket) do
    socket |> assign(changeset: Studies.change_survey_tool(%Study{}))
  end
end
