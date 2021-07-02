defmodule CoreWeb.Survey.Form do
  use CoreWeb.LiveForm
  use EyraUI.Selectors.LabelSelector

  import CoreWeb.Gettext

  alias Core.Survey.{Tools, Tool, FormData}
  alias Core.Content.Nodes

  alias CoreWeb.Router.Helpers, as: Routes

  alias EyraUI.Selectors.LabelSelector
  alias EyraUI.Spacing
  alias EyraUI.Panel.Panel
  alias EyraUI.Text.{Title3, Title6, BodyMedium}
  alias EyraUI.Form.{Form, UrlInput, TextInput, NumberInput}
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Button.{SecondaryLiveViewButton}

  prop(entity_id, :any, required: true)
  prop(uri_origin, :any, required: true)

  data(entity, :any)
  data(form_data, :any)
  data(changeset, :any)
  data(focus, :any, default: "")

  def update(%{id: id, entity_id: entity_id, uri_origin: uri_origin}, socket) do
    entity = Tools.get_survey_tool!(entity_id)

    {
      :ok,
      socket
      |> assign(entity_id: entity_id)
      |> assign(entity: entity)
      |> assign(id: id)
      |> assign(uri_origin: uri_origin)
      |> update_ui()
    }
  end

  defp update_ui(%{assigns: %{entity: entity}} = socket) do
    update_ui(socket, entity)
  end

  defp update_ui(socket, entity) do
    form_data = FormData.create(entity)
    changeset = FormData.changeset(form_data, :update_ui, %{})

    socket
    |> assign(entity: entity)
    |> assign(form_data: form_data)
    |> assign(changeset: changeset)
  end

  # Handle Events
  def handle_event("save", %{"form_data" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> schedule_save(entity, :auto_save, attrs)
      |> update_ui()
    }
  end

  def handle_event("delete", _params, %{assigns: %{entity_id: entity_id}} = socket) do
    Tools.get_survey_tool!(entity_id)
    |> Tools.delete_survey_tool()

    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Dashboard))}
  end

  # Saving
  def schedule_save(socket, %Core.Survey.Tool{} = entity, type, attrs) do
    node = Nodes.get!(entity.content_node_id)
    changeset = Tool.changeset(entity, type, attrs)
    node_changeset = Tool.node_changeset(node, entity, attrs)

    socket |> schedule_save(changeset, node_changeset)
  end

  # Label Selector (Themes)

  def all_labels(socket) do
    socket.assigns.form_data.device_labels
  end

  def update_selected_labels(%{assigns: %{entity: entity}} = socket, labels) do
    socket |> schedule_save(entity, :update, %{devices: labels})
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <Form id={{@id}} changeset={{@changeset}} change_event="save" target={{@myself}} focus={{@focus}}>
          <Panel bg_color="bg-grey1">
            <Title3 color="text-white">{{dgettext("eyra-survey", "redirect.title")}}</Title3>
            <BodyMedium color="text-white">{{dgettext("eyra-survey", "redirect.description")}}</BodyMedium>
            <Spacing value="S" />
            <Title6 color="text-white">{{dgettext("eyra-survey", "redirect.label")}}</Title6>
            <BodyMedium color="text-tertiary">{{ @uri_origin <> CoreWeb.Router.Helpers.live_path(@socket, CoreWeb.Survey.Complete, @entity_id)}}</BodyMedium>
          </Panel>
          <Spacing value="L" />
          <UrlInput field={{:survey_url}} label_text={{dgettext("eyra-survey", "config.url.label")}} target={{@myself}}/>
          <Spacing value="M" />

          <TextInput field={{:duration}} label_text={{dgettext("eyra-survey", "duration.label")}} target={{@myself}} />
          <Spacing value="M" />

          <NumberInput field={{:reward_value}} label_text={{dgettext("eyra-survey", "reward.label")}} target={{@myself}} />
          <Spacing value="M" />

          <NumberInput field={{:subject_count}} label_text={{dgettext("eyra-survey", "config.nrofsubjects.label")}} target={{@myself}} />
          <Spacing value="M" />

          <Title3>{{dgettext("eyra-survey", "devices.title")}}</Title3>
          <BodyMedium>{{dgettext("eyra-survey", "devices.label")}}</BodyMedium>
          <Spacing value="XS" />
          <LabelSelector labels={{ @form_data.device_labels }} target={{@myself}}/>
        </Form>
        <Spacing value="XL" />
        <SecondaryLiveViewButton label={{ dgettext("eyra-survey", "delete.button") }} event="delete" target={{@myself}} />
      </ContentArea>
    """
  end
end
