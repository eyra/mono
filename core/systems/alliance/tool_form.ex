defmodule Systems.Alliance.ToolForm do
  use CoreWeb.LiveForm

  import CoreWeb.UI.StepIndicator

  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Text
  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Button

  alias Systems.{
    Alliance
  }

  # Handle initial update
  @impl true
  def update(
        %{
          id: id,
          entity: entity,
          callback_url: callback_url,
          user: user
        },
        socket
      ) do
    changeset = Alliance.ToolModel.changeset(entity, :create, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
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
  def handle_event("save", %{"tool_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
    }
  end

  @impl true
  def handle_event("change", _, socket) do
    {
      :noreply,
      socket
    }
  end

  # Saving

  def save(socket, entity, type, attrs) do
    changeset = Alliance.ToolModel.changeset(entity, type, attrs)

    socket
    |> save(changeset)
    |> validate_for_publish()
  end

  # Validate

  def validate_for_publish(%{assigns: %{entity: entity}} = socket) do
    changeset =
      Alliance.ToolModel.operational_changeset(entity, %{})
      |> Map.put(:action, :validate_for_publish)

    socket
    |> assign(changeset: changeset)
  end

  defp redirect_instructions_link() do
    link_as_string(
      dgettext("eyra-alliance", "redirect.instructions.link"),
      "https://www.qualtrics.com/support/survey-platform/survey-module/survey-options/survey-termination/#RedirectingRespondentsToAUrl"
    )
  end

  defp nextid_instructions_link() do
    link_as_string(
      dgettext("eyra-alliance", "nextid.instructions.link"),
      "https://www.qualtrics.com/support/survey-platform/survey-module/survey-flow/standard-elements/passing-information-through-query-strings/?parent=p001135#PassingInformationIntoASurvey"
    )
  end

  defp study_instructions_link() do
    link_as_string(
      dgettext("eyra-alliance", "study.instructions.link"),
      "https://www.qualtrics.com/support/survey-platform/distributions-module/web-distribution/anonymous-link/#ObtainingTheAnonymousLink"
    )
  end

  defp link_as_string(label, url) do
    label
    |> link(
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
      <.form id={"#{@id}_alliance_tool_form"} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
        <Panel.flat bg_color="bg-grey1">
          <Text.title3 color="text-white"><%= dgettext("eyra-alliance", "setup.title") %></Text.title3>
          <.spacing value="M" />
          <div class="flex flex-col gap-8">
            <!-- STEP 1 -->
            <div class="flex flex-row gap-4">
              <div class="flex-wrap">
                <.step_indicator text="1" bg_color="bg-tertiary" text_color="text-grey1" />
              </div>
              <div class="flex-wrap">
                <Text.title5 align="text-left" color="text-white"><%= dgettext("eyra-alliance", "nextid.title") %></Text.title5>
                <.spacing value="XS" />
                <Text.body_medium color="text-white"><%= raw(dgettext("eyra-alliance", "nextid.description", link: nextid_instructions_link())) %></Text.body_medium>
              </div>
            </div>
            <!-- STEP 2 -->
            <div class="flex flex-row gap-4">
              <div class="flex-wrap">
                <.step_indicator text="2" bg_color="bg-tertiary" text_color="text-grey1" />
              </div>
              <div class="flex-wrap">
                <Text.title5 align="text-left" color="text-white"><%= dgettext("eyra-alliance", "redirect.title") %></Text.title5>
                <.spacing value="XS" />
                <Text.body_medium color="text-white"><%= raw(dgettext("eyra-alliance", "redirect.description", link: redirect_instructions_link())) %></Text.body_medium>
                <.spacing value="XS" />
                <div class="flex flex-row gap-6 items-center">
                  <div class="flex-wrap">
                    <Text.body_medium color="text-tertiary"><span class="break-all"><%= @callback_url %></span></Text.body_medium>
                  </div>
                  <div class="flex-wrap flex-shrink-0 mt-1">
                    <div id="copy-redirect-url" class="cursor-pointer" phx-hook="Clipboard" data-text={@callback_url}>
                      <Button.Face.label_icon
                        label={dgettext("eyra-alliance", "redirect.copy.button")}
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
                <Text.title5 align="text-left" color="text-white"><%= dgettext("eyra-alliance", "link.title") %></Text.title5>
                <.spacing value="XS" />
                <Text.body_medium color="text-white"><%= raw(dgettext("eyra-alliance", "link.description", link: study_instructions_link())) %></Text.body_medium>
              </div>
            </div>
          </div>
          <.spacing value="M" />
        </Panel.flat>
        <.spacing value="L" />

        <.url_input form={form} field={:url} label_text={dgettext("eyra-alliance", "config.url.label")} />
        <.spacing value="XL" />
      </.form>
    </div>
    """
  end
end
