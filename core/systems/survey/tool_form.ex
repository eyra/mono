defmodule Systems.Survey.ToolForm do
  use CoreWeb.LiveForm

  alias CoreWeb.UI.StepIndicator

  alias Frameworks.Pixel.Panel.Panel
  alias Frameworks.Pixel.Text.{Title3, Title5, BodyLarge, BodyMedium}
  alias Frameworks.Pixel.Form.{Form, UrlInput}
  alias Frameworks.Pixel.Button.Face.LabelIcon

  alias Systems.{
    Survey
  }

  prop entity_id, :number, required: true
  prop callback_url, :string, required: true
  prop validate?, :boolean, required: true

  data(entity, :any)
  data(changeset, :any)
  data(focus, :any, default: "")
  data(panlid_link, :any)

  # Handle update from parent after attempt to publish
  def update(%{validate?: new}, %{assigns: %{validate?: current}} = socket)
      when new != current do
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
  def update(
        %{id: id, entity_id: entity_id, validate?: validate?, callback_url: callback_url},
        socket
      ) do
    entity = Survey.Context.get_survey_tool!(entity_id)

    changeset = Survey.ToolModel.changeset(entity, :create, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id,
        entity: entity,
        callback_url: callback_url,
        changeset: changeset,
        validate?: validate?
      )
      |> validate_for_publish()
    }
  end

  # Handle Events

  @impl true
  def handle_event("save", %{"tool_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
    }
  end

  # Saving

  def save(socket, entity, type, attrs) do
    changeset = Survey.ToolModel.changeset(entity, type, attrs)

    socket
    |> save(changeset)
    |> validate_for_publish()
  end

  # Validate

  def validate_for_publish(%{assigns: %{id: id, entity: entity, validate?: true}} = socket) do
    changeset =
      Survey.ToolModel.operational_changeset(entity, %{})
      |> Map.put(:action, :validate_for_publish)

    send(self(), %{id: id, ready?: changeset.valid?})

    socket
    |> assign(changeset: changeset)
  end

  def validate_for_publish(socket), do: socket

  defp redirect_instructions_link() do
    link_as_string(
      dgettext("link-survey", "redirect.instructions.link"),
      "https://www.qualtrics.com/support/survey-platform/survey-module/survey-options/survey-termination/#RedirectingRespondentsToAUrl"
    )
  end

  defp panlid_instructions_link() do
    link_as_string(
      dgettext("link-survey", "panlid.instructions.link"),
      "https://www.qualtrics.com/support/survey-platform/survey-module/survey-flow/standard-elements/passing-information-through-query-strings/?parent=p001135#PassingInformationIntoASurvey"
    )
  end

  defp study_instructions_link() do
    link_as_string(
      dgettext("link-survey", "study.instructions.link"),
      "https://www.qualtrics.com/support/survey-platform/distributions-module/web-distribution/anonymous-link/#ObtainingTheAnonymousLink"
    )
  end

  defp link_as_string(label, url) do
    label
    |> Phoenix.HTML.Link.link(
      class: "text-white underline",
      target: "_blank",
      to: url
    )
    |> Phoenix.HTML.safe_to_string()
  end

  def render(assigns) do
    ~F"""
      <div class="-mb-8">
        <Form id={@id} changeset={@changeset} change_event="save" target={@myself} focus={@focus}>
          <Title3>{dgettext("link-survey", "form.title")}</Title3>
          <BodyLarge>{dgettext("link-survey", "form.description")}</BodyLarge>
          <Spacing value="M" />

          <Panel bg_color="bg-grey1">
            <Title3 color="text-white">{dgettext("link-survey", "setup.title")}</Title3>
            <Spacing value="M" />
            <div class="flex flex-col gap-8">
              <!-- STEP 1 -->
              <div class="flex flex-row gap-4">
                <div class="flex-wrap">
                  <StepIndicator vm={text: "1", bg_color: "bg-tertiary", text_color: "text-grey1"} />
                </div>
                <div class="flex-wrap">
                  <Title5 color="text-white">{dgettext("link-survey", "panlid.title")}</Title5>
                  <Spacing value="XS" />
                  <BodyMedium color="text-white">{raw(dgettext("link-survey", "panlid.description", link: panlid_instructions_link()))}</BodyMedium>
                </div>
              </div>
              <!-- STEP 2 -->
              <div class="flex flex-row gap-4">
                <div class="flex-wrap">
                  <StepIndicator vm={text: "2", bg_color: "bg-tertiary", text_color: "text-grey1"} />
                </div>
                <div class="flex-wrap">
                  <Title5 color="text-white">{dgettext("link-survey", "redirect.title")}</Title5>
                  <Spacing value="XS" />
                  <BodyMedium color="text-white">{raw(dgettext("link-survey", "redirect.description", link: redirect_instructions_link()))}</BodyMedium>
                  <Spacing value="XS" />
                  <div class="flex flex-row gap-6 items-center">
                    <div class="flex-wrap">
                      <BodyMedium color="text-tertiary"><span class="break-all">{@callback_url}</span></BodyMedium>
                    </div>
                    <div class="flex-wrap flex-shrink-0 mt-1">
                      <div id="copy-redirect-url" class="cursor-pointer" phx-hook="Clipboard" data-text={@callback_url} >
                        <LabelIcon vm={%{ label: dgettext("link-survey", "redirect.copy.button"),  icon: :clipboard_tertiary, text_color: "text-tertiary" }} />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <!-- STEP 3 -->
              <div class="flex flex-row gap-4">
                <div class="flex-wrap">
                  <StepIndicator vm={text: "3", bg_color: "bg-tertiary", text_color: "text-grey1"} />
                </div>
                <div class="flex-wrap">
                  <Title5 color="text-white">{dgettext("link-survey", "study.link.title")}</Title5>
                  <Spacing value="XS" />
                  <BodyMedium color="text-white">{raw(dgettext("link-survey", "study.link.description", link: study_instructions_link()))}</BodyMedium>
                </div>
              </div>
            </div>
            <Spacing value="M" />
          </Panel>
          <Spacing value="L" />

          <UrlInput field={:survey_url} label_text={dgettext("link-survey", "config.url.label")} />
        </Form>
      </div>
    """
  end
end
