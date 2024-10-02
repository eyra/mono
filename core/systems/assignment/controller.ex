defmodule Systems.Assignment.Controller do
  alias Hex.Solver.Assignment
  use CoreWeb, :controller

  import Frameworks.Utility.List, only: [append: 2, append_if: 3]
  import Systems.Assignment.Private, only: [task_identifier: 3, declined_consent?: 2]

  alias Plug.Conn
  alias CoreWeb.UI.Timestamp
  alias Frameworks.Concept
  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Workflow

  @progress_header_participant dgettext("eyra-assignment", "progress.header.participant")
  @progress_header_consent dgettext("eyra-assignment", "progress.header.consent")
  @progress_not_applicable dgettext("eyra-assignment", "progress.not.applicable")
  @progress_yes dgettext("eyra-assignment", "progress.yes")
  @progress_no dgettext("eyra-assignment", "progress.no")

  def callback(%{assigns: %{current_user: user}} = conn, %{"workflow_item_id" => item_id}) do
    %{workflow_id: workflow_id} = item = Workflow.Public.get_item!(String.to_integer(item_id))

    %{id: id, crew: crew} =
      assignment = Assignment.Public.get_by(:workflow_id, workflow_id, [:crew])

    Crew.Public.get_member(crew, user)
    |> then(&task_identifier(assignment, item, &1))
    |> then(&Crew.Public.get_task(crew, &1))
    |> Crew.Public.complete_task!()

    conn
    |> redirect(to: ~p"/assignment/#{id}")
  end

  def invite(conn, %{"id" => id}) do
    if assignment = Assignment.Public.get(String.to_integer(id), [:crew]) do
      if offline?(assignment) do
        service_unavailable(conn)
      else
        start_participant(conn, assignment)
      end
    else
      service_unavailable(conn)
    end
  end

  def apply(conn, %{"id" => id}) do
    if assignment = Assignment.Public.get(String.to_integer(id), [:crew]) do
      if offline?(assignment) do
        service_unavailable(conn)
      else
        start_participant(conn, assignment)
      end
    else
      service_unavailable(conn)
    end
  end

  def export(%{assigns: %{branch: branch}} = conn, %{"id" => id}) do
    if assignment =
         Assignment.Public.get!(
           String.to_integer(id),
           Assignment.Model.preload_graph(:down)
         ) do
      date = Timestamp.now() |> Timestamp.format_date_short!()

      branch_name =
        if branch do
          Concept.Branch.name(branch, :self)
        else
          "assignment_#{id}"
        end

      filename =
        [branch_name, "progress", date]
        |> Enum.join(" ")
        |> Slug.slugify(separator: ?_)

      csv_data = progress_csv_data(assignment)

      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\".csv")
      |> send_resp(200, csv_data)
    else
      service_unavailable(conn)
    end
  end

  def export(%Conn{} = conn, _, _) do
    service_unavailable(conn)
  end

  def progress_csv_data(%Assignment.Model{workflow: workflow} = assignment) do
    workflow_items = Workflow.Public.list_items(workflow)
    signatures = Assignment.Public.list_signatures(assignment)
    show_consent? = show_consent?(assignment, signatures)

    headers = progress_headers(workflow_items, show_consent?)
    participants = Assignment.Public.list_participants(assignment)

    progress_csv_data(
      assignment,
      headers,
      participants,
      workflow_items,
      signatures,
      show_consent?
    )
  end

  def progress_csv_data(
        assignment,
        headers,
        participants,
        workflow_items,
        signatures,
        show_consent?
      ) do
    participants
    |> Enum.map(
      &participant_progress(
        assignment,
        workflow_items,
        &1,
        participant_id(&1),
        consent(&1, signatures, show_consent?)
      )
    )
    |> CSV.encode(headers: headers)
    |> Enum.to_list()
  end

  def progress_headers(workflow_items, show_consent?) do
    # define headers to preserve order
    [@progress_header_participant]
    |> append_if(@progress_header_consent, show_consent?)
    |> append(Enum.map(workflow_items, & &1.title))
  end

  defp show_consent?(_assignment, [_ | _] = _signatures), do: true

  defp show_consent?(%Assignment.Model{consent_agreement_id: id}, _signatures) when is_number(id),
    do: true

  defp show_consent?(_, _), do: false

  defp consent(%{user_id: user_id}, signatures, show_consent?) do
    if show_consent? do
      {:include, Enum.any?(signatures, &(&1 == user_id))}
    else
      :exclude
    end
  end

  defp participant_id(%{public_id: public_id, external_id: external_id}) do
    if external_id do
      external_id
    else
      public_id
    end
  end

  defp participant_progress(
         %Assignment.Model{} = assignment,
         workflow_items,
         %{user_id: user_id, member_id: member_id},
         participant_id,
         consent
       ) do
    base =
      case consent do
        {:include, signature?} ->
          %{
            @progress_header_participant => "#{participant_id}",
            @progress_header_consent => consent_value(assignment, user_id, signature?)
          }

        :exclude ->
          %{@progress_header_participant => "#{participant_id}"}
      end

    workflow_items
    |> Enum.map(&task_status(assignment, &1, task_identifier(assignment, &1, member_id)))
    |> Enum.reduce(base, fn map, acc -> Map.merge(acc, map) end)
  end

  defp consent_value(%Assignment.Model{} = assignment, user_id, signature?) do
    cond do
      signature? ->
        @progress_yes

      declined_consent?(assignment, user_id) ->
        @progress_no

      true ->
        @progress_not_applicable
    end
  end

  defp task_status(
         %Assignment.Model{crew: crew},
         %Workflow.ItemModel{title: workflow_title},
         task_identifier
       ) do
    status_value =
      case Crew.Public.get_task(crew, task_identifier) do
        %{started_at: nil} -> @progress_not_applicable
        %{status: status} -> Crew.TaskStatus.translate(status)
        _ -> @progress_not_applicable
      end

    %{workflow_title => status_value}
  end

  defp offline?(%{status: status}) do
    status != :online
  end

  defp service_unavailable(conn) do
    conn
    |> put_status(:service_unavailable)
    |> put_view(html: CoreWeb.ErrorHTML)
    |> render(:"503")
  end

  defp start_participant(conn, %{id: id} = assignment) do
    conn
    |> authorize_user(assignment)
    |> add_panel_info(assignment)
    |> redirect(to: ~p"/assignment/#{id}")
  end

  defp add_panel_info(%{assigns: %{current_user: user}} = conn, assignment) do
    {:ok, participant} = Assignment.Public.participant_id(assignment, user)

    panel_info = %{
      panel: :next,
      embedded?: false,
      participant: participant,
      query_string: []
    }

    conn |> put_session(:panel_info, panel_info)
  end

  defp authorize_user(%{assigns: %{current_user: user}} = conn, %Assignment.Model{} = assignment) do
    Assignment.Public.add_participant!(assignment, user)
    conn
  end
end
