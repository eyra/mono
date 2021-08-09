defmodule Link.Survey.Form do
  use CoreWeb.LiveForm

  import CoreWeb.Gettext

  alias Core.Enums.Devices
  alias Core.Survey.{Tools, Tool}

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
  data(device_labels, :list)
  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle selector update
  def update(%{active_label_ids: active_label_ids, selector_id: selector_id},

  %{assigns: %{entity: entity}} = socket) do
    {
      :ok,
      socket
      |> save(entity, :auto_save, %{selector_id => active_label_ids})
    }
  end

  # Handle update from parent after save
  def update(_params, %{assigns: %{entity: _entity}} = socket) do
    {
      :ok,
      socket
    }
  end

  # Handle initial update
  def update(%{id: id, entity_id: entity_id, uri_origin: uri_origin}, socket) do
    entity = Tools.get_survey_tool!(entity_id)
    changeset = Tool.changeset(entity, :create, %{})

    device_labels = Devices.labels(entity.devices)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(entity_id: entity_id)
      |> assign(entity: entity)
      |> assign(changeset: changeset)
      |> assign(device_labels: device_labels)
      |> assign(uri_origin: uri_origin)
    }
  end

  # Handle Events

  def handle_event("save", %{"tool" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
    }
  end

  def handle_event("delete", _params, %{assigns: %{entity_id: entity_id}} = socket) do
    Tools.get_survey_tool!(entity_id)
    |> Tools.delete_survey_tool()

    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Dashboard))}
  end

  # Saving
  def save(socket, entity, type, attrs) do
    changeset = Tool.changeset(entity, type, attrs)

    socket |> schedule_save(changeset)
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <Form id={{@id}} changeset={{@changeset}} change_event="save" target={{@myself}} focus={{@focus}}>
          <Panel bg_color="bg-grey1">
            <Title3 color="text-white">{{dgettext("link-survey", "redirect.title")}}</Title3>
            <BodyMedium color="text-white">{{dgettext("link-survey", "redirect.description")}}</BodyMedium>
            <Spacing value="S" />
            <Title6 color="text-white">{{dgettext("link-survey", "redirect.label")}}</Title6>
            <BodyMedium color="text-tertiary">{{ @uri_origin <> CoreWeb.Router.Helpers.live_path(@socket, Link.Survey.Complete, @entity_id)}}</BodyMedium>
          </Panel>
          <Spacing value="L" />
          <UrlInput field={{:survey_url}} label_text={{dgettext("link-survey", "config.url.label")}} target={{@myself}}/>
          <Spacing value="M" />

          <TextInput field={{:duration}} label_text={{dgettext("link-survey", "duration.label")}} target={{@myself}} />
          <Spacing value="M" />

          <NumberInput field={{:reward_value}} label_text={{dgettext("link-survey", "reward.label")}} target={{@myself}} />
          <Spacing value="M" />

          <NumberInput field={{:subject_count}} label_text={{dgettext("link-survey", "config.nrofsubjects.label")}} target={{@myself}} />
          <Spacing value="M" />

          <Title3>{{dgettext("link-survey", "devices.title")}}</Title3>
          <BodyMedium>{{dgettext("link-survey", "devices.label")}}</BodyMedium>
          <Spacing value="XS" />
          <LabelSelector id={{:devices}} labels={{ @device_labels }} parent={{ %{type: __MODULE__, id: @id} }} />
        </Form>
        <Spacing value="XL" />
        <SecondaryLiveViewButton label={{ dgettext("link-survey", "delete.button") }} event="delete" target={{@myself}} />
      </ContentArea>
    """
  end
end
