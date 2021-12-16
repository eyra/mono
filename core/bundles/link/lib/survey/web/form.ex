defmodule Link.Survey.Form do
  use CoreWeb.LiveForm

  alias Core.Enums.Devices
  alias Link.Enums.OnlineStudyLanguages
  alias Core.Survey.{Tools, Tool}
  alias Phoenix.LiveView

  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Panel.Panel
  alias Frameworks.Pixel.Text.{Title2, Title3, Title5, Body, BodyLarge, BodyMedium}
  alias Frameworks.Pixel.Form.{Form, TextInput, UrlInput, NumberInput, Checkbox}
  alias Frameworks.Pixel.Button.Face.LabelIcon
  alias Frameworks.Pixel.Wrap

  alias CoreWeb.UI.StepIndicator

  alias Systems.{
    Assignment
  }

  prop(props, :map, required: true)

  data(entity, :any)
  data(entity_id, :any)
  data(assignment, :any)
  data(uri_origin, :any)
  data(device_labels, :list)
  data(language_labels, :list)
  data(ethical_label, :any)
  data(changeset, :any)
  data(focus, :any, default: "")
  data(panlid_link, :any)

  # Handle selector update

  def update(
        %{active_item_ids: active_item_ids, selector_id: :ethical_approval},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :ok,
      socket
      |> save(entity, :auto_save, %{ethical_approval: not Enum.empty?(active_item_ids)})
    }
  end

  def update(
        %{active_item_id: active_item_id, selector_id: :language},
        %{assigns: %{entity: entity}} = socket
      ) do
    language =
      case active_item_id do
        nil -> nil
        item when is_atom(item) -> Atom.to_string(item)
        _ -> active_item_id
      end

    {
      :ok,
      socket
      |> save(entity, :auto_save, %{language: language})
    }
  end

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
  def update(%{props: %{validate?: new}}, %{assigns: %{validate?: current}} = socket)
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
        %{
          id: id,
          props: %{user: user, entity_id: entity_id, uri_origin: uri_origin, validate?: validate?}
        },
        socket
      ) do
    entity = Tools.get_survey_tool!(entity_id)
    %{crew: crew} = assignment = Assignment.Context.get_by_assignable(entity, [:crew])

    # TBD: improve cleanup of temp roles with TTL or some other generic solution.
    if Core.Authorization.user_has_role?(user, crew, :tester) do
      Core.Authorization.remove_role!(user, crew, :tester)
    end

    changeset = Tool.changeset(entity, :create, %{})

    device_labels = Devices.labels(entity.devices)
    language_labels = OnlineStudyLanguages.labels(entity.language)

    ethical_label = %{
      id: :statement,
      value: dgettext("link-survey", "ethical.label"),
      accent: :tertiary,
      active: entity.ethical_approval
    }

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(entity_id: entity_id)
      |> assign(entity: entity)
      |> assign(assignment: assignment)
      |> assign(uri_origin: uri_origin)
      |> assign(changeset: changeset)
      |> assign(device_labels: device_labels)
      |> assign(ethical_label: ethical_label)
      |> assign(language_labels: language_labels)
      |> assign(uri_origin: uri_origin)
      |> assign(validate?: validate?)
      |> validate_for_publish()
    }
  end

  # Handle Events

  @impl true
  def handle_event(
        "test-roundtrip",
        _params,
        %{assigns: %{user: user, changeset: changeset, entity: entity, assignment: %{crew: crew}}} =
          socket
      ) do
    changeset = Tool.validate(changeset, :roundtrip)

    if changeset.valid? do
      if not Core.Authorization.can_access?(user, crew, Systems.Assignment.CallbackPage) do
        Core.Authorization.assign_role(user, crew, :tester)
      end

      fake_panl_id = "TEST-" <> Faker.UUID.v4()
      path = Assignment.Assignable.path(entity, fake_panl_id)

      {:noreply, LiveView.redirect(socket, external: path)}
    else
      {:noreply, socket |> assign(changeset: changeset)}
    end
  end

  @impl true
  def handle_event("toggle", %{"checkbox" => checkbox}, %{assigns: %{entity: entity}} = socket) do
    field = String.to_existing_atom(checkbox)

    new_value =
      case Map.get(entity, field) do
        nil -> true
        value -> not value
      end

    attrs = %{field => new_value}

    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
    }
  end

  @impl true
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
    |> save(changeset)
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

  defp ethical_review_link() do
    link_as_string(
      dgettext("link-survey", "ethical.review.link"),
      "https://vueconomics.eu.qualtrics.com/jfe/form/SV_1SKjMzceWRZIk9D"
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
    ~H"""
      <ContentArea class="mb-4" >
        <MarginY id={{:page_top}} />
        <Title2>{{dgettext("link-survey", "form.title")}}</Title2>
        <BodyLarge>{{ dgettext("link-survey", "form.description") }}</BodyLarge>
        <Spacing value="M" />
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
                  <BodyMedium color="text-white">{{ raw(dgettext("link-survey", "redirect.description", link: redirect_instructions_link()))}}</BodyMedium>
                  <Spacing value="XS" />
                  <div class="flex flex-row gap-6 items-center">
                    <div class="flex-wrap">
                      <BodyMedium color="text-tertiary"><span class="break-all">{{ @uri_origin <> CoreWeb.Router.Helpers.live_path(@socket, Systems.Assignment.CallbackPage, @assignment.id)}}</span></BodyMedium>
                    </div>
                    <div class="flex-wrap flex-shrink-0 mt-1">
                      <div id="copy-redirect-url" class="cursor-pointer" phx-hook="Clipboard" data-text={{ @uri_origin <> CoreWeb.Router.Helpers.live_path(@socket, Systems.Assignment.CallbackPage, @assignment.id)}} >
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
          <Spacing value="S" />
          <Panel bg_color="bg-grey5">
            <Title3>{{dgettext("link-survey", "test.roundtrip.title")}}</Title3>
            <Spacing value="M" />
            <BodyMedium>{{dgettext("link-survey", "test.roundtrip.text")}}</BodyMedium>
            <Spacing value="M" />
            <Wrap>
              <DynamicButton vm={{ %{
                action: %{type: :send, event: "test-roundtrip", target: @myself},
                face: %{type: :primary, label: dgettext("link-survey", "test.roundtrip.button"), bg_color: "bg-tertiary", text_color: "text-grey1"}
              } }} />
            </Wrap>
          </Panel>
          <Spacing value="XL" />

          <NumberInput field={{:duration}} label_text={{dgettext("link-survey", "duration.label")}} />
          <Spacing value="M" />

          <NumberInput field={{:subject_count}} label_text={{dgettext("link-survey", "config.nrofsubjects.label")}} />
          <Spacing value="M" />

          <Title3>{{dgettext("link-survey", "language.title")}}</Title3>
          <Body>{{dgettext("link-survey", "languages.label")}}</Body>
          <Spacing value="S" />
          <Selector
            id={{:language}}
            items={{ @language_labels }}
            type={{:radio}}
            parent={{ %{type: __MODULE__, id: @id} }}
          />
          <Spacing value="XL" />

          <Title3>{{dgettext("link-survey", "devices.title")}}</Title3>
          <Body>{{dgettext("link-survey", "devices.label")}}</Body>
          <Spacing value="S" />
          <Selector
            id={{:devices}}
            items={{ @device_labels }}
            parent={{ %{type: __MODULE__, id: @id} }}
          />
          <Spacing value="XL" />

          <Panel bg_color="bg-grey1">
            <Title3 color="text-white" >{{dgettext("link-survey", "ethical.title")}}</Title3>
            <BodyMedium color="text-white">{{ raw(dgettext("link-survey", "ethical.description", link: ethical_review_link()))}}</BodyMedium>
            <Spacing value="S" />
            <TextInput field={{:ethical_code}} placeholder={{dgettext("eyra-account", "ehtical.code.label")}} background={{:dark}} />
            <Checkbox
              field={{:ethical_approval}}
              label_text={{ dgettext("link-survey", "ethical.label")}}
              label_color="text-white"
              accent={{:tertiary}}
              background={{:dark}}
            />
          </Panel>

        </Form>
      </ContentArea>
    """
  end
end
