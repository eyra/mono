defmodule Systems.Assignment.CrewPageRequiredTasksTest do
  use MicaWeb.ConnCase, async: false
  use Oban.Testing, repo: Mica.Repo
  import Phoenix.LiveViewTest

  alias Systems.Account
  alias Systems.Assignment
  alias Systems.Consent
  alias Systems.Crew
  alias Systems.Workflow

  setup :login_as_member

  setup %{user: user} do
    assignment =
      Assignment.Factories.create_template_assignment(:data_donation, [
        :manual,
        :donate,
        :questionnaire
      ])

    revision = Factories.insert!(:consent_revision, %{agreement: assignment.consent_agreement})
    Account.Public.mark_as_visited(user, {:assignment_information, assignment.id})
    Assignment.Public.add_participant!(assignment, user)

    %{assignment: assignment, revision: revision}
  end

  describe "a data donation workflow with a manual" do
    test "shows the done screen right after the last required task, without the manual", %{
      conn: conn,
      assignment: assignment,
      revision: revision,
      user: user
    } do
      {:ok, _} = Consent.Public.create_signature(revision, user)
      page = open_crew_page(conn, assignment)
      assert has_element?(page, "[data-testid='crew-task-list-view']")

      complete_in_task_list(page, item(assignment, :donate))
      refute has_element?(page, "[data-testid='finished-view']")

      complete_in_task_list(page, item(assignment, :questionnaire))
      assert eventually_has_element?(page, "[data-testid='finished-view']")
    end

    test "shows the done screen right after the last required task, after signing consent in the same visit",
         %{conn: conn, assignment: assignment, revision: revision, user: user} do
      page = open_crew_page(conn, assignment)
      refute has_element?(page, "[data-testid='crew-task-list-view']")

      # As the consent clickwrap does
      {:ok, _} = Consent.Public.create_signature(revision, user)
      send_event(page, :accept)
      assert eventually_has_element?(page, "[data-testid='crew-task-list-view']")

      complete_in_task_list(page, item(assignment, :donate))
      complete_in_task_list(page, item(assignment, :questionnaire))
      assert eventually_has_element?(page, "[data-testid='finished-view']")
    end

    test "stays on the task list while the donation is open", %{
      conn: conn,
      assignment: assignment,
      revision: revision,
      user: user
    } do
      {:ok, _} = Consent.Public.create_signature(revision, user)
      page = open_crew_page(conn, assignment)

      complete_in_task_list(page, item(assignment, :questionnaire))
      complete_in_task_list(page, item(assignment, :manual))
      assert %{status: :completed} = task(assignment, user, :manual)

      assert has_element?(page, "[data-testid='crew-task-list-view']")
      refute has_element?(page, "[data-testid='finished-view']")

      refute match?(
               %{completed_at: %NaiveDateTime{}},
               Assignment.Public.get_participation(assignment, user)
             )
    end

    test "shows the done screen on a later visit, with the manual still open", %{
      conn: conn,
      assignment: assignment,
      revision: revision,
      user: user
    } do
      {:ok, _} = Consent.Public.create_signature(revision, user)
      complete_task(assignment, user, :donate)
      complete_task(assignment, user, :questionnaire)

      page = open_crew_page(conn, assignment)

      assert has_element?(page, "[data-testid='finished-view']")
      assert %{status: :pending} = task(assignment, user, :manual)
    end

    test "with an end-of-workflow URL, the done screen continues to the panel", %{
      conn: conn,
      assignment: assignment,
      revision: revision,
      user: user
    } do
      {:ok, _} = Consent.Public.create_signature(revision, user)
      page = open_crew_page(conn, assignment, "https://panel.example/done")

      complete_in_task_list(page, item(assignment, :donate))
      complete_in_task_list(page, item(assignment, :questionnaire))

      assert eventually_has_element?(page, "[data-testid='finished-view']")
      assert has_element?(page, "a[href='https://panel.example/done']")
    end
  end

  defp open_crew_page(conn, assignment, redirect_url \\ nil) do
    panel_info = %{panel: :affiliate, redirect_url: redirect_url, participant: "p1"}

    {:ok, page, _html} =
      conn |> put_session(:panel_info, panel_info) |> live(~p"/assignment/#{assignment.id}")

    page
  end

  defp send_event(view, name, payload \\ %{}) do
    send(view.pid, {:live_nest_event, %LiveNest.Event{name: name, payload: payload}})
    render(view)
  end

  # As the participant does: open the task, then its tool reports completion.
  defp complete_in_task_list(page, %Workflow.ItemModel{id: item_id}) do
    task_list = find_child(page, Assignment.CrewTaskListView)
    send_event(task_list, :work_item_selected, %{"item" => "#{item_id}"})
    send_event(task_list, :tool_completed)
    render(page)
  end

  defp find_child(view, module) do
    Enum.find_value(live_children(view), fn child ->
      if child.module == module, do: child, else: find_child(child, module)
    end)
  end

  defp item(%{workflow: workflow}, special) do
    Enum.find(workflow.items, &(&1.tool_ref.special == special))
  end

  defp task(%{crew: crew} = assignment, user, special) do
    member = Crew.Public.get_member(crew, user)
    identifier = Assignment.Private.task_identifier(assignment, item(assignment, special), member)
    Crew.Public.get_task(crew, identifier) || Crew.Public.create_task!(crew, [user], identifier)
  end

  defp complete_task(assignment, user, special) do
    {:ok, _} = Crew.Public.complete_task(task(assignment, user, special))
  end
end
