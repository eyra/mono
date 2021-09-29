defmodule Link.Survey.Form do
  use CoreWeb.LiveForm

  alias Core.Enums.Devices
  alias Link.Enums.OnlineStudyLanguages
  alias Core.Survey.{Tools, Tool}

  alias EyraUI.Selector.Selector
  alias EyraUI.Panel.Panel
  alias EyraUI.Text.{Title2, Title3, Title5, BodyMedium}
  alias EyraUI.Form.{Form, UrlInput, TextInput, NumberInput}
  alias EyraUI.Button.Face.LabelIcon

  alias CoreWeb.UI.StepIndicator

  prop(props, :map, required: true)

  data(entity, :any)
  data(entity_id, :any)
  data(uri_origin, :any)
  data(device_labels, :list)
  data(language_labels, :list)
  data(changeset, :any)
  data(focus, :any, default: "")
  data(panlid_link, :any)

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

  # Handle update from parent after attempt to publish
  def update(%{props: %{validate?: new}}, %{assigns: %{validate?: current}} = socket) when new != current do
    {
      :ok,
      socket
      |> assign(validate?: new)
      |> validate_for_publish()
    }
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{entity: _entity}} = socket) do
    {:ok, socket}
  end

  # Handle initial update
  def update(%{id: id, props: %{entity_id: entity_id, uri_origin: uri_origin, validate?: validate?}}, socket) do
    entity = Tools.get_survey_tool!(entity_id)
    changeset = Tool.changeset(entity, :create, %{})

    device_labels = Devices.labels(entity.devices)
    language_labels = OnlineStudyLanguages.labels(entity.language)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(entity_id: entity_id)
      |> assign(entity: entity)
      |> assign(uri_origin: uri_origin)
      |> assign(changeset: changeset)
      |> assign(device_labels: device_labels)
      |> assign(language_labels: language_labels)
      |> assign(uri_origin: uri_origin)
      |> assign(validate?: validate?)
      |> validate_for_publish()
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

    socket
    |> schedule_save(changeset)
    |> validate_for_publish()
  end

  # Validate

  def validate_for_publish(%{assigns: %{id: id, entity: entity, validate?: true}} = socket) do
    changeset =
      Tool.operational_changeset(entity, %{})
      |> Map.put(:action, :validate_for_publish)

    send(self(), %{id: id, ready?: changeset.valid?})

    socket
    |> assign(changeset: changeset)
  end

  def validate_for_publish(socket), do: socket

  defp panlid_instructions_link() do
    link_as_string(
      dgettext("link-survey", "panlid.link"),
      "https://www.qualtrics.com/support/survey-platform/survey-module/survey-flow/standard-elements/passing-information-through-query-strings/?parent=p001135#PassingInformationIntoASurvey"
    )
  end

  defp study_instructions_link() do
    link_as_string(
      dgettext("link-survey", "study.link"),
      "https://www.qualtrics.com/support/survey-platform/distributions-module/web-distribution/anonymous-link/#ObtainingTheAnonymousLink"
    )
  end

  defp link_as_string(label, url) do
    label
    |> Phoenix.HTML.Link.link(
      class: "text-tertiary underline",
      target: "_blank",
      to: url
    )
    |> Phoenix.HTML.safe_to_string()
  end

  def render(assigns) do
    ~H"""
      <ContentArea class="mb-4" >
        <MarginY id={{:page_top}} />
        <Title2>{{dgettext("link-survey", "form.title")}}</Title2>
        <Form id={{@id}} changeset={{@changeset}} change_event="save" target={{@myself}} focus={{@focus}}>

          <Panel bg_color="bg-grey1">
            <Title3 color="text-white">{{dgettext("link-survey", "setup.title")}}</Title3>
            <Spacing value="M" />
            <div class="flex flex-col gap-8">
              <!-- STEP 1 -->
              <div class="flex flex-row gap-4">
                <div class="flex-wrap">
                  <StepIndicator vm={{ text: "1", bg_color: "bg-tertiary", text_color: "text-grey1" }} />
                </div>
                <div class="flex-wrap">
                  <Title5 color="text-white">{{dgettext("link-survey", "panlid.title")}}</Title5>
                  <Spacing value="XS" />
                  <BodyMedium color="text-white">{{ raw(dgettext("link-survey", "panlid.description", link: panlid_instructions_link())) }}</BodyMedium>
                </div>
              </div>
              <!-- STEP 2 -->
              <div class="flex flex-row gap-4">
                <div class="flex-wrap">
                  <StepIndicator vm={{ text: "2", bg_color: "bg-tertiary", text_color: "text-grey1" }} />
                </div>
                <div class="flex-wrap">
                  <Title5 color="text-white">{{dgettext("link-survey", "redirect.title")}}</Title5>
                  <Spacing value="XS" />
                  <BodyMedium color="text-white">{{dgettext("link-survey", "redirect.description")}}</BodyMedium>
                  <Spacing value="XXS" />
                  <div class="flex flex-row gap-6 items-center">
                    <div class="flex-wrap">
                      <BodyMedium color="text-tertiary"><span class="break-all">{{ @uri_origin <> CoreWeb.Router.Helpers.live_path(@socket, Link.Survey.Complete, @entity_id)}}</span></BodyMedium>
                    </div>
                    <div class="flex-wrap flex-shrink-0 mt-1">
                      <div id="copy-redirect-url" class="cursor-pointer" phx-hook="Clipboard" data-text={{ @uri_origin <> CoreWeb.Router.Helpers.live_path(@socket, Link.Survey.Complete, @entity_id)}} >
                        <LabelIcon vm={{ %{ label: dgettext("link-survey", "redirect.copy.button"),  icon: :clipboard_tertiary, text_color: "text-tertiary" } }} />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <!-- STEP 3 -->
              <div class="flex flex-row gap-4">
                <div class="flex-wrap">
                  <StepIndicator vm={{ text: "3", bg_color: "bg-tertiary", text_color: "text-grey1" }} />
                </div>
                <div class="flex-wrap">
                  <Title5 color="text-white">{{dgettext("link-survey", "study.link.title")}}</Title5>
                  <Spacing value="XS" />
                  <BodyMedium color="text-white">{{ raw(dgettext("link-survey", "study.link.description", link: study_instructions_link())) }}</BodyMedium>
                </div>
              </div>
            </div>
            <Spacing value="M" />
          </Panel>
          <Spacing value="L" />

          <UrlInput field={{:survey_url}} label_text={{dgettext("link-survey", "config.url.label")}} />
          <Spacing value="M" />

          <TextInput field={{:duration}} label_text={{dgettext("link-survey", "duration.label")}} />
          <Spacing value="M" />

          <NumberInput field={{:subject_count}} label_text={{dgettext("link-survey", "config.nrofsubjects.label")}} />
          <Spacing value="M" />

          <Title3>{{dgettext("link-survey", "language.title")}}</Title3>
          <BodyMedium>{{dgettext("link-survey", "languages.label")}}</BodyMedium>
          <Spacing value="XS" />
          <Selector id={{:language}} items={{ @language_labels }} type={{:radio}} parent={{ %{type: __MODULE__, id: @id} }} />
          <Spacing value="XL" />

          <Title3>{{dgettext("link-survey", "devices.title")}}</Title3>
          <BodyMedium>{{dgettext("link-survey", "devices.label")}}</BodyMedium>
          <Spacing value="XS" />
          <Selector id={{:devices}} items={{ @device_labels }} parent={{ %{type: __MODULE__, id: @id} }} />
          <Spacing value="XL" />

          <Panel bg_color="bg-grey1" padding="pt-6 pb-0 px-6 lg:pt-8 lg:pb-1 lg:px-8">
            <Title3 color="text-white" >{{dgettext("link-survey", "rerb.title")}}</Title3>
            <BodyMedium color="text-white">{{dgettext("link-survey", "rerb.description")}}</BodyMedium>
            <Spacing value="XS" />
            <TextInput field={{:rerb_code}} label_text={{dgettext("link-survey", "rerb.label")}} label_color="text-white" background={{ :dark }}/>
          </Panel>

        </Form>
      </ContentArea>
    """
  end
end
