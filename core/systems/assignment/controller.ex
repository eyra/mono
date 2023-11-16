defmodule Systems.Assignment.Controller do
  use CoreWeb, :controller

  alias Systems.{
    Assignment,
    Workflow,
    Crew
  }

  def callback(%{assigns: %{current_user: user}} = conn, %{"item" => item_id}) do
    %{workflow_id: workflow_id} = item = Workflow.Public.get_item!(String.to_integer(item_id))
    %{id: id, crew: crew} = assignment = Assignment.Public.get_by(workflow_id, [:crew])

    Crew.Public.get_member(crew, user)
    |> then(&Assignment.Private.task_identifier(assignment, item, &1))
    |> then(&Crew.Public.get_task(crew, &1))
    |> Crew.Public.activate_task!()

    conn
    |> redirect(to: ~p"/assignment/#{id}")
  end
end
