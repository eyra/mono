defmodule Systems.Assignment.CrewPageBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

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

      assigns = build_assigns(user)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.implementation == Assignment.CrewWorkView
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

      assigns = build_assigns(user)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.implementation == Assignment.OnboardingView
    end

    test "shows consent view when consent not signed", %{user: user} do
      assignment = Assignment.Factories.create_assignment_with_consent()
      assignment = Assignment.Factories.add_participant(assignment, user)

      assigns = build_assigns(user)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.implementation == Assignment.OnboardingConsentView
    end

    test "shows finished view when tasks finished", %{assignment: assignment, user: user} do
      assignment = Assignment.Factories.add_participant(assignment, user)
      mark_intro_visited(assignment, user)

      # Create and finish all tasks
      finish_all_tasks(assignment, user)

      assigns = build_assigns(user)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.implementation == Assignment.FinishedView
    end

    test "shows finished view when consent declined", %{user: user} do
      assignment = Assignment.Factories.create_assignment_with_consent()
      assignment = Assignment.Factories.add_participant(assignment, user)

      # First render - show consent view
      assigns = build_assigns(user)
      %{view: consent_view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)
      assert consent_view.implementation == Assignment.OnboardingConsentView

      # User declines - simulate round trip with action and vm.view from previous render
      Assignment.Public.decline_member(assignment, user)
      assigns_with_action = build_assigns(user, %{view: consent_view, action: :decline})
      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns_with_action)

      assert view.implementation == Assignment.FinishedView
    end

    test "shows consent view when returning from finished with declined consent", %{user: user} do
      assignment = Assignment.Factories.create_assignment_with_consent()
      assignment = Assignment.Factories.add_participant(assignment, user)

      # Decline consent
      Assignment.Public.decline_member(assignment, user)

      # Simulate retry from finished view by including previous view in assigns
      previous_view = %{implementation: Assignment.FinishedView}
      assigns = build_assigns(user, %{view: previous_view})

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      # Should show consent view again to allow retry
      assert view.implementation == Assignment.OnboardingConsentView
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

      assigns = build_assigns(user)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view == nil
    end
  end

  describe "finished view data building" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)

      assigns = build_assigns(user)

      %{user: user, assignment: assignment, assigns: assigns}
    end

    test "builds correct data for completed assignment without redirect", %{
      assignment: assignment,
      assigns: assigns
    } do
      # Mark tasks as finished
      mark_intro_visited(assignment, assigns.current_user)
      finish_all_tasks(assignment, assigns.current_user)

      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      assert view.implementation == Assignment.FinishedView
      assert view.options[:live_context].data[:assignment_id] == assignment.id

      # Test FinishedViewBuilder separately
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)
      assert vm.illustration == "/images/illustrations/finished.svg"
      assert vm.back_button.face.label == dgettext("eyra-assignment", "back.button")
      assert vm.continue_button == nil
    end

    test "builds correct data for declined consent", %{user: user} do
      assignment = Assignment.Factories.create_assignment_with_consent()
      assignment = Assignment.Factories.add_participant(assignment, user)

      # First render - show consent view
      assigns = build_assigns(user)
      %{view: consent_view} = Assignment.CrewPageBuilder.view_model(assignment, assigns)

      # User declines - simulate round trip with action and vm.view from previous render
      Assignment.Public.decline_member(assignment, user)
      assigns_with_action = build_assigns(user, %{view: consent_view, action: :decline})
      %{view: view} = Assignment.CrewPageBuilder.view_model(assignment, assigns_with_action)

      # After declining, finished view is shown
      assert view.implementation == Assignment.FinishedView
      assert view.options[:live_context].data[:assignment_id] == assignment.id

      # Test FinishedViewBuilder separately
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns_with_action)
      assert vm.illustration == nil
      assert vm.back_button.face.label == dgettext("eyra-assignment", "back.button")
      assert vm.continue_button == nil
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

  defp build_assigns(user, opts \\ %{}) do
    base = %{
      current_user: user,
      user_state: %{},
      live_context: nil,
      panel_info: nil
    }

    base
    |> maybe_add_vm(opts)
    |> maybe_add_action(opts)
  end

  defp maybe_add_vm(assigns, %{view: view}), do: Map.put(assigns, :vm, %{view: view})
  defp maybe_add_vm(assigns, _opts), do: assigns

  defp maybe_add_action(assigns, %{action: action}), do: Map.put(assigns, :action, action)
  defp maybe_add_action(assigns, _opts), do: assigns
end
