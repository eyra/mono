defmodule Link.Pool.CampaignSubmissionView do
  use CoreWeb.LiveForm

  alias Core.Enums.{StudyYears, StudyProgramCodes, Genders, DominantHands, NativeLanguages}

  alias EyraUI.Selector.Selector
  alias EyraUI.Text.{Title2, Title3, BodyMedium}

  alias Core.Pools.{Submissions, Criteria}

  prop(props, :any, required: true)

  data(entity, :any)
  data(study_year_labels, :any)
  data(study_program_labels, :any)
  data(gender_labels, :any)
  data(dominanthand_labels, :any)
  data(nativelanguage_labels, :any)

  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle Selector Update
  def update(
        %{active_item_id: active_study_year, selector_id: :study_year},
        %{assigns: %{criteria: criteria}} = socket
      ) do
    study_program_codes = StudyProgramCodes.values_by_year(active_study_year)
    study_year_labels = StudyYears.labels(active_study_year)

    study_program_labels =
      StudyProgramCodes.labels_by_year(active_study_year, study_program_codes)

    send_update(Selector, id: :study_program, reset: study_program_labels)

    {
      :ok,
      socket
      |> force_save(criteria, %{:study_program_codes => study_program_codes})
      |> assign(study_year_labels: study_year_labels)
      |> assign(study_program_labels: study_program_labels)
    }
  end

  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{criteria: criteria}} = socket
      ) do
    {
      :ok,
      socket
      |> force_save(criteria, %{selector_id => active_item_ids})
    }
  end

  def update(
        %{active_item_id: active_item_id, selector_id: selector_id},
        %{assigns: %{criteria: criteria}} = socket
      ) do
    {
      :ok,
      socket
      |> force_save(criteria, %{selector_id => active_item_id})
    }
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{submission: _submission}} = socket) do
    {:ok, socket}
  end

  def update(%{id: id, props: %{entity_id: entity_id}}, socket) do
    submission = Submissions.get!(entity_id)
    criteria = submission.criteria

    year =
      if StudyProgramCodes.is_first_year_active?(criteria.study_program_codes) do
        :first
      else
        :second
      end

    study_year_labels = StudyYears.labels(year)
    study_program_labels = StudyProgramCodes.labels_by_year(year, criteria.study_program_codes)

    gender_labels = Genders.labels(criteria.genders)
    dominanthand_labels = DominantHands.labels(criteria.dominant_hands)
    nativelanguage_labels = NativeLanguages.labels(criteria.native_languages)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(submission: submission)
      |> assign(criteria: criteria)
      |> assign(study_year_labels: study_year_labels)
      |> assign(study_program_labels: study_program_labels)
      |> assign(gender_labels: gender_labels)
      |> assign(dominanthand_labels: dominanthand_labels)
      |> assign(nativelanguage_labels: nativelanguage_labels)
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

  # Saving

  def force_save(socket, entity, attrs), do: save(socket, entity, attrs, false)
  def schedule_save(socket, entity, attrs), do: save(socket, entity, attrs, true)

  def save(socket, %Criteria{} = entity, attrs, schedule?) do
    changeset = Criteria.changeset(entity, attrs)

    socket
    |> save(changeset, schedule?)
    |> update_ui()
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <div class="flex flex-col-reverse xl:flex-row gap-8 xl:gap-14">
          <div class="xl:max-w-form">
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
          <div class="xl:max-w-form">
            <Title2>{{dgettext("eyra-account", "features.study.title")}}</Title2>
            <BodyMedium>{{dgettext("eyra-account", "feature.study.content.description")}}</BodyMedium>
            <Spacing value="M" />

            <Title3>{{dgettext("eyra-account", "features.study.year")}}</Title3>
            <Selector id={{:study_year}} items={{ @study_year_labels }} type={{:radio}} parent={{ %{type: __MODULE__, id: @id} }} />
            <Spacing value="XL" />

            <Title3>{{dgettext("eyra-account", "features.study.program")}}</Title3>
            <Selector id={{:study_program}} items={{ @study_program_labels }} type={{:checkbox}} parent={{ %{type: __MODULE__, id: @id} }} opts="max-w-form" />
            <Spacing value="XL" />
          </div>
        </div>
      </ContentArea>
    """
  end
end
