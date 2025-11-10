defmodule Systems.Assignment.CrewPageBuilderTest do
  use Core.DataCase

  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Account

  describe "view_model/2 - state machine" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_base_assignment()

      %{user: user, assignment: assignment}
    end

    test "shows work view when all prerequisites met", %{assignment: assignment, user: user} do
      assignment = Assignment.Factories.add_participant(assignment, user)
      mark_intro_visited(assignment, user)

      fabric = build_fabric()
      assigns = build_assigns(user, fabric)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.ref.module == Assignment.CrewWorkView
    end

    test "shows intro view when not visited", %{assignment: assignment, user: user} do
      assignment = Assignment.Factories.add_participant(assignment, user)

      # Add an intro page_ref so intro view can be shown
      page = Factories.insert!(:content_page)

      _page_ref =
        Factories.insert!(:assignment_page_ref, %{
          assignment: assignment,
          page: page,
          key: :assignment_information
        })

      assignment = Repo.preload(assignment, [:page_refs], force: true)

      fabric = build_fabric()
      assigns = build_assigns(user, fabric)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.ref.module == Assignment.OnboardingView
    end

    test "shows consent view when consent not signed", %{user: user} do
      assignment = Assignment.Factories.create_assignment_with_consent()
      assignment = Assignment.Factories.add_participant(assignment, user)

      fabric = build_fabric()
      assigns = build_assigns(user, fabric)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.ref.module == Assignment.OnboardingConsentView
    end

    test "shows finished view when tasks finished", %{assignment: assignment, user: user} do
      assignment = Assignment.Factories.add_participant(assignment, user)
      mark_intro_visited(assignment, user)

      # Create and finish all tasks
      finish_all_tasks(assignment, user)

      fabric = build_fabric()
      assigns = build_assigns(user, fabric)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.ref.module == Assignment.FinishedView
    end

    test "shows finished view when consent declined", %{user: user} do
      assignment = Assignment.Factories.create_assignment_with_consent()
      assignment = Assignment.Factories.add_participant(assignment, user)

      # Decline consent
      Assignment.Public.decline_member(assignment, user)

      fabric = build_fabric()
      assigns = build_assigns(user, fabric)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.ref.module == Assignment.FinishedView
    end

    test "shows consent view when returning from finished with declined consent", %{user: user} do
      assignment = Assignment.Factories.create_assignment_with_consent()
      assignment = Assignment.Factories.add_participant(assignment, user)

      # Decline consent
      Assignment.Public.decline_member(assignment, user)

      fabric = build_fabric()

      # Simulate retry from finished view by including previous view in assigns
      previous_view = %{module: Assignment.FinishedView}
      vm_with_finished = %{view: previous_view}
      assigns = build_assigns(user, fabric, vm_with_finished)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      # Should show consent view again to allow retry
      assert view.ref.module == Assignment.OnboardingConsentView
    end

    test "shows nil view when assignment offline and user not tester", %{
      assignment: assignment,
      user: user
    } do
      assignment =
        assignment
        |> Repo.preload([:crew])
        |> Ecto.Changeset.change(status: :offline)
        |> Repo.update!()

      fabric = build_fabric()
      assigns = build_assigns(user, fabric)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view == nil
    end
  end

  describe "finished view data building" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)

      fabric = build_fabric()
      assigns = build_assigns(user, fabric)

      %{user: user, assignment: assignment, fabric: fabric, assigns: assigns}
    end

    test "builds correct data for completed assignment without redirect", %{
      assignment: assignment,
      assigns: assigns
    } do
      # Mark tasks as finished
      mark_intro_visited(assignment, assigns.current_user)
      finish_all_tasks(assignment, assigns.current_user)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.ref.module == Assignment.FinishedView
      assert view.params.show_illustration == true
      assert view.params.retry_button != nil
      assert view.params.retry_button.face.label == "back.button"
      assert view.params.redirect_button == nil
    end

    test "builds correct data for declined consent", %{user: user, fabric: fabric} do
      assignment = Assignment.Factories.create_assignment_with_consent()
      assignment = Assignment.Factories.add_participant(assignment, user)
      Assignment.Public.decline_member(assignment, user)

      assigns = build_assigns(user, fabric)
      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.ref.module == Assignment.FinishedView
      assert view.params.show_illustration == false
      assert view.params.retry_button != nil
      assert view.params.redirect_button == nil
    end
  end

  # Helper functions
  defp mark_intro_visited(%{id: assignment_id}, user) do
    Account.Public.mark_as_visited(user, {:assignment_information, assignment_id})
  end

  defp finish_all_tasks(%{crew: crew, workflow: workflow} = assignment, user) do
    %{items: [item]} = workflow |> Repo.preload([:items])
    member = Crew.Public.get_member(crew, user)
    identifier = Assignment.Private.task_identifier(assignment, item, member)
    task = Crew.Public.create_task!(crew, [user], identifier)
    Crew.Public.complete_task!(task)
  end

  defp build_fabric do
    # Create a minimal Fabric.Model structure
    %Fabric.Model{parent: nil, self: nil, children: []}
  end

  defp build_assigns(user, fabric, vm \\ nil) do
    base = %{
      current_user: user,
      fabric: fabric,
      timezone: "UTC",
      session: %{}
    }

    if vm do
      Map.put(base, :vm, vm)
    else
      base
    end
  end
end
