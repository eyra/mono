defmodule Systems.Survey.ToolForm do
  use CoreWeb.LiveForm

  import CoreWeb.UI.StepIndicator

  alias Phoenix.LiveView
  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Text
  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Button

  alias Systems.{
    Director,
    Survey
  }

  # Handle update from parent
  @impl true
  def update(
        %{validate?: validate?, active_field: active_field},
        %{assigns: %{entity: _}} = socket
      ) do
    {
      :ok,
      socket
      |> update_validate?(validate?)
      |> update_active_field(active_field)
    }
  end

  # Handle initial update
  @impl true
  def update(
        %{
          id: id,
          entity_id: entity_id,
          validate?: validate?,
          active_field: active_field,
          callback_url: callback_url,
          user: user
        },
        socket
      ) do
    entity = Survey.Public.get_survey_tool!(entity_id)

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
        validate?: validate?,
        active_field: active_field,
        user: user
      )
      |> validate_for_publish()
    }
  end

  defp update_active_field(%{assigns: %{active_field: current}} = socket, new)
       when new != current do
    socket
    |> assign(active_field: new)
  end

  defp update_active_field(socket, _new), do: socket

  defp update_validate?(%{assigns: %{validate?: current}} = socket, new) when new != current do
    socket
    |> assign(validate?: new)
    |> validate_for_publish()
  end

  defp update_validate?(socket, _new), do: socket

  # Handle Events

  @impl true
  def handle_event(
        "test-roundtrip",
        _params,
        %{assigns: %{user: user, changeset: changeset, entity: entity}} = socket
      ) do
    changeset = Survey.ToolModel.validate(changeset, :roundtrip)

    if changeset.valid? do
      Director.public(entity).assign_tester_role(entity, user)

      fake_panl_id = "TEST-" <> Faker.UUID.v4()
      external_path = Survey.ToolModel.external_path(entity, fake_panl_id)

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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="-mb-8">
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
        <Text.title3><%= dgettext("link-survey", "form.title") %></Text.title3>
        <Text.body_large><%= dgettext("link-survey", "form.description") %></Text.body_large>
        <.spacing value="M" />

        <Panel.flat bg_color="bg-grey1">
          <Text.title3 color="text-white"><%= dgettext("link-survey", "setup.title") %></Text.title3>
          <.spacing value="M" />
          <div class="flex flex-col gap-8">
            <!-- STEP 1 -->
            <div class="flex flex-row gap-4">
              <div class="flex-wrap">
                <.step_indicator text="1" bg_color="bg-tertiary" text_color="text-grey1" />
              </div>
              <div class="flex-wrap">
                <Text.title5 align="text-left" color="text-white"><%= dgettext("link-survey", "panlid.title") %></Text.title5>
                <.spacing value="XS" />
                <Text.body_medium color="text-white"><%= raw(dgettext("link-survey", "panlid.description", link: panlid_instructions_link())) %></Text.body_medium>
              </div>
            </div>
            <!-- STEP 2 -->
            <div class="flex flex-row gap-4">
              <div class="flex-wrap">
                <.step_indicator text="2" bg_color="bg-tertiary" text_color="text-grey1" />
              </div>
              <div class="flex-wrap">
                <Text.title5 align="text-left" color="text-white"><%= dgettext("link-survey", "redirect.title") %></Text.title5>
                <.spacing value="XS" />
                <Text.body_medium color="text-white"><%= raw(dgettext("link-survey", "redirect.description", link: redirect_instructions_link())) %></Text.body_medium>
                <.spacing value="XS" />
                <div class="flex flex-row gap-6 items-center">
                  <div class="flex-wrap">
                    <Text.body_medium color="text-tertiary"><span class="break-all"><%= @callback_url %></span></Text.body_medium>
                  </div>
                  <div class="flex-wrap flex-shrink-0 mt-1">
                    <div id="copy-redirect-url" class="cursor-pointer" phx-hook="Clipboard" data-text={@callback_url}>
                      <Button.Face.label_icon
                        label={dgettext("link-survey", "redirect.copy.button")}
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
                <Text.title5 align="text-left" color="text-white"><%= dgettext("link-survey", "study.link.title") %></Text.title5>
                <.spacing value="XS" />
                <Text.body_medium color="text-white"><%= raw(dgettext("link-survey", "study.link.description", link: study_instructions_link())) %></Text.body_medium>
              </div>
            </div>
          </div>
          <.spacing value="M" />
        </Panel.flat>
        <.spacing value="L" />

        <.url_input form={form} field={:survey_url} label_text={dgettext("link-survey", "config.url.label")} active_field={@active_field} />
        <.spacing value="S" />
        <Panel.flat bg_color="bg-grey5">
          <Text.title3><%= dgettext("link-survey", "test.roundtrip.title") %></Text.title3>
          <.spacing value="M" />
          <Text.body_medium><%= dgettext("link-survey", "test.roundtrip.text") %></Text.body_medium>
          <.spacing value="M" />
          <.wrap>
            <Button.dynamic {%{
              action: %{type: :send, event: "test-roundtrip", target: @myself},
              face: %{
                type: :primary,
                label: dgettext("link-survey", "test.roundtrip.button"),
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
