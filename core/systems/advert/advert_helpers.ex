defmodule Systems.Advert.AdvertHelpers do
  @moduledoc """
  Logic is based on older logic from the submission_view.
  Receives a submission and user, performs filtering logic and returns a list of labels that are used to populate the exclude-adverts selector.
  """

  alias Systems.{Project, Assignment}
  alias Systems.Advert

  def update_adverts(%{user: user, submission: submission}) do
    %{
      id: advert_id,
      assignment:
        %{
          excluded: excluded_assignments
        } = assignment
    } =
      Advert.Public.get_by_submission(submission, assignment: [:excluded])

    excluded_assignment_ids = Enum.map(excluded_assignments, & &1.id)
    advert_labels = get_advert_labels_for_users_projects(user, advert_id, excluded_assignment_ids)
    excluded_user_ids = Assignment.Public.list_user_ids(excluded_assignment_ids)

    %{
      assignment: assignment,
      advert_labels: advert_labels,
      excluded_user_ids: excluded_user_ids
    }
  end

  defp get_advert_labels_for_users_projects(user, advert_id, excluded_assignment_ids) do
    # for each user owned project
    Project.Public.list_owned_projects(user, preload: Project.Model.preload_graph(:down))
    # get all items in each project
    |> Enum.flat_map(& &1.root.items)
    # reject items without adverts
    |> Enum.reject(&(&1.advert == nil))
    # loop through the project's adverts
    |> Enum.map(& &1.advert)
    # reject nil adverts
    |> Enum.reject(&is_nil(&1))
    # reject adverts that have no related assignment
    |> Enum.reject(&(&1.assignment_id == nil))
    # reject the advert_id (the advert being edited)
    |> Enum.filter(&(&1.id != advert_id))
    # convert to labels
    |> Enum.map(&to_label(&1, excluded_assignment_ids))
  end

  defp to_label(
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
end
