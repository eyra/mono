defmodule Systems.Advert.SubmissionViewBuilder do
  alias Frameworks.Concept.Directable
  alias Systems.{Advert, Project, Assignment, Pool}

  @enum_map %{
    genders: Core.Enums.Genders,
    native_languages: Core.Enums.NativeLanguages
  }

  def view_model(%Advert.Model{submission: submission} = advert, %{current_user: user}) do
    criteria = submission.criteria
    pool = submission.pool
    selector_option_labels = get_inclusion_criteria_labels(pool, criteria)
    changeset = Pool.CriteriaModel.changeset(criteria, %{})

    %{
      assignment: assignment,
      advert_labels: advert_labels,
      excluded_user_ids: excluded_user_ids
    } = adverts_state(user, submission)

    %{
      sample_size: sample_size,
      pool_size: pool_size,
      pool_title: pool_title
    } = pool_stats(pool, criteria, excluded_user_ids)

    %{
      advert: advert,
      entity: submission,
      user: user,
      assignment: assignment,
      advert_labels: advert_labels,
      excluded_user_ids: excluded_user_ids,
      selector_option_labels: selector_option_labels,
      sample_size: sample_size,
      pool_size: pool_size,
      pool_title: pool_title,
      changeset: changeset
    }
  end

  defp adverts_state(user, submission) do
    %{
      id: advert_id,
      assignment:
        %{
          excluded: excluded_assignments
        } = assignment
    } = Advert.Public.get_by_submission(submission, assignment: [:excluded])

    excluded_assignment_ids = Enum.map(excluded_assignments, & &1.id)
    advert_labels = advert_labels_for_users_projects(user, advert_id, excluded_assignment_ids)
    excluded_user_ids = Assignment.Public.list_user_ids(excluded_assignment_ids)

    %{
      assignment: assignment,
      advert_labels: advert_labels,
      excluded_user_ids: excluded_user_ids
    }
  end

  # Build labels for adverts from the user's owned projects, excluding the
  # advert currently being edited and adverts without an assignment.
  defp advert_labels_for_users_projects(user, advert_id, excluded_assignment_ids) do
    Project.Public.list_owned_projects(user, preload: Project.Model.preload_graph(:down))
    |> Enum.flat_map(& &1.root.items)
    |> Enum.reject(&(&1.advert == nil))
    |> Enum.map(& &1.advert)
    |> Enum.reject(&(is_nil(&1) or &1.assignment_id == nil or &1.id == advert_id))
    |> Enum.map(&to_advert_label(&1, excluded_assignment_ids))
  end

  defp to_advert_label(
         %Advert.Model{
           id: id,
           promotion: %{title: title},
           assignment_id: assignment_id
         },
         excluded_assignment_ids
       ) do
    excluded = Enum.member?(excluded_assignment_ids, assignment_id)
    %{id: to_string(id), value: title, active: excluded}
  end

  def get_inclusion_criteria_labels(pool, %Pool.CriteriaModel{} = criteria) do
    Directable.director(pool).inclusion_criteria()
    |> Enum.map(&labels_for_field(&1, criteria))
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  # birth_years are handled with number inputs, not selectors
  defp labels_for_field(:birth_years, %Pool.CriteriaModel{}), do: nil

  # genders: filter out "prefer_not_to_say" as it is not a valid inclusion criterium
  defp labels_for_field(:genders, %Pool.CriteriaModel{} = criteria) do
    enum_module = Map.fetch!(@enum_map, :genders)

    allowed_values =
      enum_module.values()
      |> Enum.reject(&(&1 == :prefer_not_to_say))

    {:genders, enum_module.labels(Map.get(criteria, :genders, []), allowed_values)}
  end

  defp labels_for_field(field, %Pool.CriteriaModel{} = criteria) when is_atom(field) do
    case Map.get(@enum_map, field) do
      nil -> nil
      enum_module -> {field, enum_module.labels(Map.get(criteria, field))}
    end
  end

  defp pool_stats(
         %Pool.Model{name: pool_name} = pool,
         %Pool.CriteriaModel{} = criteria,
         excluded_user_ids
       ) do
    user_ids_in_pool =
      pool
      |> Pool.Public.list_participants()
      |> Enum.map(& &1.id)

    pool_size = Enum.count(user_ids_in_pool)
    pool_title = Pool.Model.title(pool_name)

    sample_size =
      Pool.Public.count_eligitable_users(criteria, user_ids_in_pool, excluded_user_ids)

    %{sample_size: sample_size, pool_size: pool_size, pool_title: pool_title}
  end
end
