defmodule Systems.Assignment.Controller do
  use CoreWeb, :controller

  alias Systems.Assignment
  alias Systems.Workflow
  alias Systems.Crew

  def callback(%{assigns: %{current_user: user}} = conn, %{"item" => item_id}) do
    %{workflow_id: workflow_id} = item = Workflow.Public.get_item!(String.to_integer(item_id))

    %{id: id, crew: crew} =
      assignment = Assignment.Public.get_by(:workflow_id, workflow_id, [:crew])

    Crew.Public.get_member(crew, user)
    |> then(&Assignment.Private.task_identifier(assignment, item, &1))
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
