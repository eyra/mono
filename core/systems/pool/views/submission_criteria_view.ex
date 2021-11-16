defmodule Systems.Pool.SubmissionCriteriaView do
  use CoreWeb.LiveForm

  alias Core.Enums.{StudyYears, StudyProgramCodes}

  alias EyraUI.Selector.Selector
  alias EyraUI.Text.Title3

  alias Core.Pools.{Submissions, Criteria}

  prop(props, :any, required: true)

  data(submission, :any)
  data(study_year_labels, :any)
  data(study_program_labels, :any)
  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle Selector Update
  def update(
        %{active_item_id: active_item_id, selector_id: :study_year},
        %{assigns: %{criteria: criteria}} = socket
      ) do
    study_program_codes = StudyProgramCodes.values_by_year(active_item_id)
    study_year_labels = StudyYears.labels(active_item_id)
    study_program_labels = StudyProgramCodes.labels_by_year(active_item_id, study_program_codes)
    send_update(Selector, id: :study_program, reset: study_program_labels)

    {
      :ok,
      socket
      |> save(criteria, %{:study_program_codes => study_program_codes})
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
      |> save(criteria, %{selector_id => active_item_ids})
    }
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{submission: _submission}} = socket) do
    {:ok, socket}
  end

  def update(%{id: id, props: %{entity_id: entity_id}}, socket) do
    criteria = Submissions.get!(entity_id).criteria

    year =
      if StudyProgramCodes.is_first_year_active?(criteria.study_program_codes) do
        :first
      else
        :second
      end

    study_year_labels = StudyYears.labels(year)
    study_program_labels = StudyProgramCodes.labels_by_year(year, criteria.study_program_codes)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(
        criteria: criteria,
        study_year_labels: study_year_labels,
        study_program_labels: study_program_labels
      )
      |> update_ui()
    }
  end

  defp update_ui(%{assigns: %{criteria: criteria}} = socket) do
    update_ui(socket, criteria)
  end

  defp update_ui(socket, criteria) do
    study_labels = StudyProgramCodes.labels(criteria.study_program_codes)

    socket
    |> assign(study_labels: study_labels)
  end

  # Saving
  def save(socket, %Criteria{} = entity, attrs) do
    changeset = Criteria.changeset(entity, attrs)

    socket
    |> save(changeset)
    |> update_ui()
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <Title3 margin="mb-5 sm:mb-8">{{dgettext("eyra-account", "features.study.year")}}</Title3>
        <Selector id={{:study_year}} items={{ @study_year_labels }} type={{:radio}} parent={{ %{type: __MODULE__, id: @id} }} />
        <Spacing value="L" />

        <Title3 margin="mb-5 sm:mb-8">{{dgettext("eyra-account", "features.study.program")}}</Title3>
        <Selector id={{:study_program}} items={{ @study_program_labels }} type={{:checkbox}} parent={{ %{type: __MODULE__, id: @id} }} opts="max-w-form" />
      </ContentArea>
    """
  end
end
