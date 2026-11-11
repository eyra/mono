defmodule Systems.Assignment.CrewPageRequiredTasksTest do
  use MicaWeb.ConnCase, async: false
  use Oban.Testing, repo: Mica.Repo
  import Phoenix.LiveViewTest

  alias Mica.Repo
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

  describe "a participant who did the donation and questionnaire before the manuals stopped counting" do
    setup %{assignment: assignment, revision: revision, user: user} do
      join_from_panel(assignment, user)
      {:ok, _} = Consent.Public.create_signature(revision, user)

      # Before the migration every item counted, so the open manual kept them unfinished
      set_required(assignment, :manual, true)
      open_tasks(assignment, user)
      complete_task(assignment, user, :donate)
      complete_task(assignment, user, :questionnaire)
      set_required(assignment, :manual, false)
      :ok
    end

    test "is not finished before they open the assignment", %{assignment: assignment, user: user} do
      refute completed?(assignment, user)
      assert [] = progress_events(user, "assignment_finished")
    end

    test "is finished when they open the assignment", %{
      conn: conn,
      assignment: assignment,
      user: user
    } do
      open_crew_page(conn, assignment)
      assert completed?(assignment, user)
    end

    test "gets one assignment_finished when they open the assignment", %{
      conn: conn,
      assignment: assignment,
      user: user
    } do
      open_crew_page(conn, assignment)
      assert ["assignment_finished"] = progress_events(user, "assignment_finished")
    end

    test "is counted as finished in the Monitor when they open the assignment", %{
      conn: conn,
      assignment: assignment
    } do
      open_crew_page(conn, assignment)
      assert 1 = finished_count(assignment)
    end

    test "gets no second assignment_finished on a second visit", %{
      conn: conn,
      assignment: assignment,
      user: user
    } do
      open_crew_page(conn, assignment)
      open_crew_page(conn, assignment)
      assert ["assignment_finished"] = progress_events(user, "assignment_finished")
    end
  end

  # Before the participation had `completed_at`, the rule then (all tasks finished) already
  # sent these participants assignment_finished and logged the Monitor event, so a visit
  # must not send it again; also not after a manual was added to the workflow later.
  for participation <- [:without_completed_at, :without_participation],
      workflow <- [:unchanged, :manual_added_later] do
    @participation participation
    @workflow workflow

    describe "a participant who finished all tasks before completion was recorded (#{participation}, #{workflow})" do
      setup %{assignment: assignment, revision: revision, user: user} do
        join_from_panel(assignment, user)
        {:ok, _} = Consent.Public.create_signature(revision, user)
        open_tasks(assignment, user)
        finish_as_before_completion_was_recorded(assignment, user)

        if @participation == :without_completed_at do
          {:ok, %{completed_at: nil}} = Assignment.Public.obtain_participation(assignment, user)
        end

        if @workflow == :manual_added_later do
          add_download_manual_and_open_it(assignment, user)
        end

        :ok
      end

      test "gets no assignment_finished when they open the assignment", %{
        conn: conn,
        assignment: assignment,
        user: user
      } do
        open_crew_page(conn, assignment)
        assert [] = progress_events(user, "assignment_finished")
      end

      test "gets no second Monitor finished event when they open the assignment", %{
        conn: conn,
        assignment: assignment
      } do
        open_crew_page(conn, assignment)
        assert 1 = finished_rows(assignment)
      end

      test "is not completed when they open the assignment", %{
        conn: conn,
        assignment: assignment,
        user: user
      } do
        open_crew_page(conn, assignment)
        refute completed?(assignment, user)
      end
    end
  end

  describe "a researcher removing a participant's last open required item" do
    setup %{assignment: assignment, revision: revision, user: user} do
      join_from_panel(assignment, user)
      {:ok, _} = Consent.Public.create_signature(revision, user)
      open_tasks(assignment, user)
      complete_task(assignment, user, :donate)

      {:ok, _} = Workflow.Public.delete(item(assignment, :questionnaire))
      :ok
    end

    test "finishes nobody", %{assignment: assignment, user: user} do
      refute completed?(assignment, user)
      assert [] = progress_events(user, "assignment_finished")
    end

    test "finishes the participant once they open the assignment", %{
      conn: conn,
      assignment: assignment,
      user: user
    } do
      open_crew_page(conn, assignment)
      assert completed?(assignment, user)
      assert ["assignment_finished"] = progress_events(user, "assignment_finished")
    end
  end

  describe "a researcher removing a participant's last open required item, with nothing else open" do
    setup %{assignment: assignment, revision: revision, user: user} do
      join_from_panel(assignment, user)
      {:ok, _} = Consent.Public.create_signature(revision, user)
      open_tasks(assignment, user)
      complete_task(assignment, user, :manual)
      complete_task(assignment, user, :donate)

      {:ok, _} = Workflow.Public.delete(item(assignment, :questionnaire))
      :ok
    end

    test "finishes the participant once they open the assignment", %{
      conn: conn,
      assignment: assignment,
      user: user
    } do
      open_crew_page(conn, assignment)
      assert completed?(assignment, user)
    end

    test "sends one assignment_finished once they open the assignment", %{
      conn: conn,
      assignment: assignment,
      user: user
    } do
      open_crew_page(conn, assignment)
      assert ["assignment_finished"] = progress_events(user, "assignment_finished")
    end
  end

  describe "a participant who presses Done before their last required task" do
    setup %{conn: conn, assignment: assignment, revision: revision, user: user} do
      join_from_panel(assignment, user)
      {:ok, _} = Consent.Public.create_signature(revision, user)
      page = open_crew_page(conn, assignment)
      complete_in_task_list(page, item(assignment, :donate))

      # The task list's "Next, I am done" button
      send_event(page, :work_done)
      completed_after_done = completed?(assignment, user)

      complete_task(assignment, user, :questionnaire)
      %{completed_after_done: completed_after_done}
    end

    test "is completed by Done", %{completed_after_done: completed_after_done} do
      assert completed_after_done
    end

    test "gets assignment_finished once their last required task completes", %{user: user} do
      assert ["assignment_finished"] = progress_events(user, "assignment_finished")
    end
  end

  describe "a tester whose required tasks are done but who wasn't finished then" do
    setup %{assignment: assignment, revision: revision, user: user} do
      join_from_panel(assignment, user)
      Assignment.Factories.add_tester(assignment, user)
      {:ok, _} = Consent.Public.create_signature(revision, user)

      set_required(assignment, :manual, true)
      open_tasks(assignment, user)
      complete_task(assignment, user, :donate)
      complete_task(assignment, user, :questionnaire)
      set_required(assignment, :manual, false)
      :ok
    end

    test "gets no assignment_finished on their visits", %{
      conn: conn,
      assignment: assignment,
      user: user
    } do
      open_crew_page(conn, assignment)
      open_crew_page(conn, assignment)
      assert [] = progress_events(user, "assignment_finished")
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

  # As the task list does when it renders: every item gets its task
  defp open_tasks(assignment, user) do
    for special <- [:manual, :donate, :questionnaire], do: task(assignment, user, special)
  end

  # The data of a participant who finished before completion was recorded: every task
  # finished and the Monitor event the old rule's dispatch logged, but no completed_at.
  defp finish_as_before_completion_was_recorded(%{crew: crew} = assignment, user) do
    for special <- [:manual, :donate, :questionnaire] do
      assignment
      |> task(user, special)
      |> Ecto.Changeset.change(status: :completed)
      |> Repo.update!()
    end

    member = Crew.Public.get_member(crew, user)
    Assignment.Private.log_performance_event(assignment, :finished, member)
  end

  defp add_download_manual_and_open_it(%{workflow_id: workflow_id} = assignment, user) do
    %{library: %{items: library}} =
      :data_donation
      |> Assignment.Private.get_template()
      |> Assignment.Template.workflow_config()

    download_manual = Enum.find(library, &(&1.id == :download_manual))
    owner = Factories.insert!(:member)

    {:ok, %{workflow_item: item}} =
      Workflow.Public.add_item(workflow_id, download_manual, :assignment, owner)

    member = Crew.Public.get_member(assignment.crew, user)
    identifier = Assignment.Private.task_identifier(assignment, item, member)
    Crew.Public.create_task!(assignment.crew, [user], identifier)
  end

  defp complete_task(assignment, user, special) do
    {:ok, _} = Crew.Public.complete_task(task(assignment, user, special))
  end

  # A participant who entered through a panel link with a callback URL
  defp join_from_panel(%{affiliate: affiliate} = assignment, user) do
    Repo.update!(Ecto.Changeset.change(affiliate, callback_url: "https://panel.example/cb"))
    Assignment.Factories.add_affiliate_user(assignment, user, "p1")
  end

  defp set_required(assignment, special, required) do
    item = Repo.reload!(item(assignment, special))
    Repo.update!(Ecto.Changeset.change(item, required: required))
  end

  defp completed?(assignment, user) do
    match?(
      %{completed_at: %NaiveDateTime{}},
      Assignment.Public.get_participation(assignment, user)
    )
  end

  defp progress_events(%{id: user_id}, progress) do
    for %{args: %{"user_id" => ^user_id, "event" => %{"progress" => ^progress}}} <-
          all_enqueued(worker: Systems.Affiliate.CallbackWorker),
        do: progress
  end

  defp finished_rows(assignment) do
    Systems.Monitor.Public.event({assignment, :finished}) |> Systems.Monitor.Public.count()
  end

  defp finished_count(assignment) do
    Systems.Monitor.Public.event({assignment, :finished}) |> Systems.Monitor.Public.unique()
  end
end
