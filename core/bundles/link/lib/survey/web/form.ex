defmodule Link.Survey.Form do
  use CoreWeb.LiveForm

  alias Core.Enums.Devices
  alias Core.Survey.{Tools, Tool}

  alias EyraUI.Selector.Selector
  alias EyraUI.Panel.Panel
  alias EyraUI.Text.{Title2, Title3, Title6, BodyMedium}
  alias EyraUI.Form.{Form, UrlInput, TextInput, NumberInput}

  prop(props, :map, required: true)

  data(entity, :any)
  data(entity_id, :any)
  data(uri_origin, :any)
  data(device_labels, :list)
  data(changeset, :any)
  data(focus, :any, default: "")
  data(qualtrics_url?, :any, default: false)

  # Handle selector update
  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :ok,
      socket
      |> save(entity, :auto_save, %{selector_id => active_item_ids})
    }
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{entity: _entity}} = socket) do
    {:ok, socket}
  end

  # Handle initial update
  def update(%{id: id, props: %{entity_id: entity_id, uri_origin: uri_origin}}, socket) do
    entity = Tools.get_survey_tool!(entity_id)
    changeset = Tool.changeset(entity, :create, %{})

    device_labels = Devices.labels(entity.devices)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(entity_id: entity_id)
      |> assign(entity: entity)
      |> assign(uri_origin: uri_origin)
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

  # Saving
  def save(socket, entity, type, attrs) do
    changeset = Tool.changeset(entity, type, attrs)

    socket |> schedule_save(changeset)
  end

  def render(assigns) do
    assigns =
      Map.put(
        assigns,
        :qualtrics_url?,
        Ecto.Changeset.apply_changes(assigns.changeset).survey_url
        |> String.contains?("qualtrics.com")
      )

    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Title2>{{dgettext("link-survey", "form.title")}}</Title2>
        <Form id={{@id}} changeset={{@changeset}} change_event="save" target={{@myself}} focus={{@focus}}>
          <Panel bg_color="bg-grey1">
            <Title3 color="text-white">{{dgettext("link-survey", "redirect.title")}}</Title3>
            <BodyMedium color="text-white">{{dgettext("link-survey", "redirect.description")}}</BodyMedium>
            <Spacing value="S" />
            <Title6 color="text-white">{{dgettext("link-survey", "redirect.label")}}</Title6>
            <BodyMedium color="text-tertiary">{{ @uri_origin <> CoreWeb.Router.Helpers.live_path(@socket, Link.Survey.Complete, @entity_id)}}</BodyMedium>
          </Panel>
          <Spacing value="L" />
          <UrlInput field={{:survey_url}} label_text={{dgettext("link-survey", "config.url.label")}}>
            <BodyMedium>{{dgettext("link-survey", "config.url.description")}}</BodyMedium>
            <BodyMedium :if={{@qualtrics_url?}}>
              See the
              <a href="https://www.qualtrics.com/support/survey-platform/survey-module/survey-flow/standard-elements/passing-information-through-query-strings/?parent=p001135#PassingInformationIntoASurvey">instructions for Qualtrics</a>
              on how to setup the Qualtrics side.
            </BodyMedium>
          </UrlInput>
          <Spacing value="M" />

          <TextInput field={{:duration}} label_text={{dgettext("link-survey", "duration.label")}} />
          <Spacing value="M" />

          <NumberInput field={{:subject_count}} label_text={{dgettext("link-survey", "config.nrofsubjects.label")}} />
          <Spacing value="M" />

          <Title3>{{dgettext("link-survey", "devices.title")}}</Title3>
          <BodyMedium>{{dgettext("link-survey", "devices.label")}}</BodyMedium>
          <Spacing value="XS" />
          <Selector id={{:devices}} items={{ @device_labels }} parent={{ %{type: __MODULE__, id: @id} }} />
        </Form>
      </ContentArea>
    """
  end
end
