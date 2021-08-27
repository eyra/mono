defmodule Link.Pool.Form.Submission do
  use CoreWeb.LiveForm

  alias Core.Enums.{StudyProgramCodes, Genders, DominantHands, NativeLanguages}

  alias EyraUI.Selector.Selector
  alias EyraUI.Text.{Title2, Title3, BodyMedium}

  alias Core.Content.Nodes
  alias Core.Pools.{Submissions, Criteria}

  prop(props, :any, required: true)

  data(entity, :any)
  data(study_labels, :any)
  data(gender_labels, :any)
  data(dominanthand_labels, :any)
  data(nativelanguage_labels, :any)
  data(buttons, :map)

  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle Selector Update
  def update(
        %{active_item_id: active_item_id, selector_id: selector_id},
        %{assigns: %{criteria: criteria}} = socket
      ) do
    {
      :ok,
      socket
      |> save(criteria, :auto_save, %{selector_id => active_item_id})
    }
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{submission: _submission}} = socket) do
    {:ok, socket}
  end

  def update(%{id: id, props: %{entity_id: entity_id}}, socket) do
    submission = Submissions.get!(entity_id)
    criteria = submission.criteria

    study_labels = StudyProgramCodes.labels(criteria.study_program_codes)
    gender_labels = Genders.labels(criteria.genders)
    dominanthand_labels = DominantHands.labels(criteria.dominant_hands)
    nativelanguage_labels = NativeLanguages.labels(criteria.native_languages)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(submission: submission)
      |> assign(criteria: criteria)
      |> assign(study_labels: study_labels)
      |> assign(gender_labels: gender_labels)
      |> assign(dominanthand_labels: dominanthand_labels)
      |> assign(nativelanguage_labels: nativelanguage_labels)
      |> update_buttons()
      |> update_ui()
    }
  end

  defp update_ui(%{assigns: %{criteria: criteria}} = socket) do
    update_ui(socket, criteria)
  end

  defp update_ui(socket, criteria) do
    study_labels = StudyProgramCodes.labels(criteria.study_program_codes)
    gender_labels = Genders.labels(criteria.genders)
    dominanthand_labels = DominantHands.labels(criteria.dominant_hands)
    nativelanguage_labels = NativeLanguages.labels(criteria.native_languages)

    socket
    |> assign(study_labels: study_labels)
    |> assign(gender_labels: gender_labels)
    |> assign(dominanthand_labels: dominanthand_labels)
    |> assign(nativelanguage_labels: nativelanguage_labels)
  end

  defp update_buttons(%{assigns: %{submission: submission, myself: myself }} = socket) do
    submitted? = submission.status === :submitted

    buttons =
      [
        if submitted? do
          %{
            action: %{ type: :send, event: "retract", target: myself},
            face: %{ type: :secondary, label: dgettext("eyra-submission", "retract.button") }
          }
        else
          %{
            action: %{ type: :send, event: "submit", target: myself},
            face: %{ type: :primary, label: dgettext("eyra-submission", "submit.button")}
          }
        end
      ]

    socket |> assign(buttons: buttons)
  end

  # Events
  def handle_event("submit", _params, %{assigns: %{submission: submission}} = socket) do
    socket =
    if Nodes.ready?(submission.content_node) do
      {:ok, submission} = Submissions.update(submission, %{status: :submitted})
      socket
      |> assign(submission: submission)
      |> update_buttons()
    else
      socket
      |> flash_error(dgettext("eyra-submission", "submit.error"))
    end

    { :noreply, socket}
  end

  def handle_event("retract", _params, %{assigns: %{submission: submission}} = socket) do
    {:ok, submission} = Submissions.update(submission, %{status: :idle})

    {
      :noreply,
      socket
      |> assign(submission: submission)
      |> update_buttons()
    }
  end

  # Saving
  def save(socket, %Criteria{} = criteria, _type, attrs) do
    changeset = Criteria.changeset(criteria, attrs)

    socket
    |> schedule_save(changeset)
    |> update_ui()
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <div class="grid grid-cols-2 gap-14">
          <div class="max-w-form">
            <Title2>{{dgettext("eyra-account", "features.title")}}</Title2>
            <BodyMedium>{{dgettext("eyra-account", "features.content.description")}}</BodyMedium>
            <Spacing value="M" />

            <Title3>{{dgettext("eyra-account", "features.gender.title")}}</Title3>
            <Selector id={{:genders}} items={{ @gender_labels }} type={{:checkbox}} parent={{ %{type: __MODULE__, id: @id} }} />
            <Spacing value="XL" />

            <Title3>{{dgettext("eyra-account", "features.nativelanguage.title")}}</Title3>
            <Selector id={{:native_languages}} items={{ @nativelanguage_labels }} type={{:checkbox}} parent={{ %{type: __MODULE__, id: @id} }} />
            <Spacing value="XL" />

            <Title3>{{dgettext("eyra-account", "features.dominanthand.title")}}</Title3>
            <Selector id={{:dominant_hands}} items={{ @dominanthand_labels }} type={{:checkbox}} parent={{ %{type: __MODULE__, id: @id} }} />
          </div>
          <div class="max-w-form">
            <Title2>{{dgettext("eyra-account", "features.study.title")}}</Title2>
            <BodyMedium>{{dgettext("eyra-account", "feature.study.content.description")}}</BodyMedium>
            <Spacing value="S" />
            <Selector id={{:study_program_codes}} items={{ @study_labels }} type={{:checkbox}} parent={{ %{type: __MODULE__, id: @id} }}/>
            <Spacing value="XL" />
          </div>
        </div>
        <Spacing value="XL" />
        <div class="flex flex-row gap-6 ml-">
          <DynamicButton :for={{ button <- @buttons }} vm={{ button }} />
        </div>
      </ContentArea>
    """
  end
end
