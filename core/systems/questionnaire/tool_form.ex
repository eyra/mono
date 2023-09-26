defmodule Systems.Questionnaire.ToolForm do
  use CoreWeb.LiveForm

  import CoreWeb.UI.StepIndicator

  alias Phoenix.LiveView
  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Text
  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Button

  alias Systems.{
    Director,
    Questionnaire
  }

  # Handle initial update
  @impl true
  def update(
        %{
          id: id,
          entity_id: entity_id,
          callback_url: callback_url,
          user: user
        },
        socket
      ) do
    entity = Questionnaire.Public.get_questionnaire_tool!(entity_id)

    changeset = Questionnaire.ToolModel.changeset(entity, :create, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id,
        entity: entity,
        callback_url: callback_url,
        changeset: changeset,
        user: user
      )
      |> validate_for_publish()
    }
  end

  # Handle Events

  @impl true
  def handle_event(
        "test-roundtrip",
        _params,
        %{assigns: %{user: user, changeset: changeset, entity: entity}} = socket
      ) do
    changeset = Questionnaire.ToolModel.validate(changeset, :roundtrip)

    if changeset.valid? do
      Director.public(entity).assign_tester_role(entity, user)

      fake_panl_id = "TEST-" <> Faker.UUID.v4()
      external_path = Questionnaire.ToolModel.external_path(entity, fake_panl_id)

      {:noreply, LiveView.redirect(socket, external: external_path)}
    else
      {:noreply, socket |> assign(changeset: changeset)}
    end
  end

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
    changeset = Questionnaire.ToolModel.changeset(entity, type, attrs)

    socket
    |> save(changeset)
    |> validate_for_publish()
  end

  # Validate

  def validate_for_publish(%{assigns: %{id: id, entity: entity}} = socket) do
    changeset =
      Questionnaire.ToolModel.operational_changeset(entity, %{})
      |> Map.put(:action, :validate_for_publish)

    send(self(), %{id: id, ready?: changeset.valid?})

    socket
    |> assign(changeset: changeset)
  end

  defp redirect_instructions_link() do
    link_as_string(
      dgettext("link-questionnaire", "redirect.instructions.link"),
      "https://www.qualtrics.com/support/survey-platform/survey-module/survey-options/survey-termination/#RedirectingRespondentsToAUrl"
    )
  end

  defp panlid_instructions_link() do
    link_as_string(
      dgettext("link-questionnaire", "panlid.instructions.link"),
      "https://www.qualtrics.com/support/survey-platform/survey-module/survey-flow/standard-elements/passing-information-through-query-strings/?parent=p001135#PassingInformationIntoAQuestionnaire"
    )
  end

  defp study_instructions_link() do
    link_as_string(
      dgettext("link-questionnaire", "study.instructions.link"),
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="-mb-8">
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
        <Text.title3><%= dgettext("link-questionnaire", "form.title") %></Text.title3>
        <Text.body_large><%= dgettext("link-questionnaire", "form.description") %></Text.body_large>
        <.spacing value="M" />

        <Panel.flat bg_color="bg-grey1">
          <Text.title3 color="text-white"><%= dgettext("link-questionnaire", "setup.title") %></Text.title3>
          <.spacing value="M" />
          <div class="flex flex-col gap-8">
            <!-- STEP 1 -->
            <div class="flex flex-row gap-4">
              <div class="flex-wrap">
                <.step_indicator text="1" bg_color="bg-tertiary" text_color="text-grey1" />
              </div>
              <div class="flex-wrap">
                <Text.title5 align="text-left" color="text-white"><%= dgettext("link-questionnaire", "panlid.title") %></Text.title5>
                <.spacing value="XS" />
                <Text.body_medium color="text-white"><%= raw(dgettext("link-questionnaire", "panlid.description", link: panlid_instructions_link())) %></Text.body_medium>
              </div>
            </div>
            <!-- STEP 2 -->
            <div class="flex flex-row gap-4">
              <div class="flex-wrap">
                <.step_indicator text="2" bg_color="bg-tertiary" text_color="text-grey1" />
              </div>
              <div class="flex-wrap">
                <Text.title5 align="text-left" color="text-white"><%= dgettext("link-questionnaire", "redirect.title") %></Text.title5>
                <.spacing value="XS" />
                <Text.body_medium color="text-white"><%= raw(dgettext("link-questionnaire", "redirect.description", link: redirect_instructions_link())) %></Text.body_medium>
                <.spacing value="XS" />
                <div class="flex flex-row gap-6 items-center">
                  <div class="flex-wrap">
                    <Text.body_medium color="text-tertiary"><span class="break-all"><%= @callback_url %></span></Text.body_medium>
                  </div>
                  <div class="flex-wrap flex-shrink-0 mt-1">
                    <div id="copy-redirect-url" class="cursor-pointer" phx-hook="Clipboard" data-text={@callback_url}>
                      <Button.Face.label_icon
                        label={dgettext("link-questionnaire", "redirect.copy.button")}
                        icon={:clipboard_tertiary}
                        text_color="text-tertiary"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <!-- STEP 3 -->
            <div class="flex flex-row gap-4">
              <div class="flex-wrap">
                <.step_indicator text="3" bg_color="bg-tertiary" text_color="text-grey1" />
              </div>
              <div class="flex-wrap">
                <Text.title5 align="text-left" color="text-white"><%= dgettext("link-questionnaire", "study.link.title") %></Text.title5>
                <.spacing value="XS" />
                <Text.body_medium color="text-white"><%= raw(dgettext("link-questionnaire", "study.link.description", link: study_instructions_link())) %></Text.body_medium>
              </div>
            </div>
          </div>
          <.spacing value="M" />
        </Panel.flat>
        <.spacing value="L" />

        <.url_input form={form} field={:questionnaire_url} label_text={dgettext("link-questionnaire", "config.url.label")} />
        <.spacing value="S" />
        <Panel.flat bg_color="bg-grey5">
          <Text.title3><%= dgettext("link-questionnaire", "test.roundtrip.title") %></Text.title3>
          <.spacing value="M" />
          <Text.body_medium><%= dgettext("link-questionnaire", "test.roundtrip.text") %></Text.body_medium>
          <.spacing value="M" />
          <.wrap>
            <Button.dynamic {%{
              action: %{type: :send, event: "test-roundtrip", target: @myself},
              face: %{
                type: :primary,
                label: dgettext("link-questionnaire", "test.roundtrip.button"),
                bg_color: "bg-tertiary",
                text_color: "text-grey1"
              }
            }} />
          </.wrap>
        </Panel.flat>
        <.spacing value="XL" />
      </.form>
    </div>
    """
  end
end
