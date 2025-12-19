defmodule Systems.Assignment.CrewWorkViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)

      %{user: user, assignment: assignment}
    end

    test "builds task view when user_state present", %{
      assignment: assignment,
      user: user
    } do
      assigns = build_assigns(user, %{})
      vm = Assignment.CrewWorkViewBuilder.view_model(assignment, assigns)

      # Should have task view for single item
      assert vm.task_view != nil
      assert vm.task_view.implementation == Assignment.CrewTaskSingleView
      assert String.starts_with?(vm.task_view.id, "crew_task_single_view_")
    end

    test "builds nil task view when user_state is nil", %{
      assignment: assignment,
      user: user
    } do
      assigns = build_assigns(user, nil)
      vm = Assignment.CrewWorkViewBuilder.view_model(assignment, assigns)

      # Should have nil task view (waiting for user_state)
      assert vm.task_view == nil
    end

    test "builds context menu items when all available", %{user: user} do
      # Create assignment with all context menu items
      assignment = Assignment.Factories.create_assignment_with_consent()
      assignment = Assignment.Factories.add_participant(assignment, user)

      # Add privacy doc
      privacy_doc = Factories.insert!(:content_file, %{ref: "https://example.com/privacy.pdf"})

      assignment =
        assignment
        |> Ecto.Changeset.change(privacy_doc: privacy_doc)
        |> Repo.update!()

      # Add page refs
      info_page = Factories.insert!(:content_page)
      support_page = Factories.insert!(:content_page)

      Factories.insert!(:assignment_page_ref, %{
        assignment: assignment,
        page: info_page,
        key: :assignment_information
      })

      Factories.insert!(:assignment_page_ref, %{
        assignment: assignment,
        page: support_page,
        key: :assignment_helpdesk
      })

      assignment =
        Repo.preload(assignment, [:page_refs, :privacy_doc, :consent_agreement], force: true)

      assigns = build_assigns(user, %{})
      vm = Assignment.CrewWorkViewBuilder.view_model(assignment, assigns)

      # Should have all 4 context menu items
      assert length(vm.context_menu_items) == 4

      # Check each context menu item
      info_item = Enum.find(vm.context_menu_items, &(&1.id == :assignment_information))
      assert info_item.label == dgettext("eyra-assignment", "context.menu.information.title")

      privacy_item = Enum.find(vm.context_menu_items, &(&1.id == :privacy))
      assert privacy_item.label == dgettext("eyra-assignment", "context.menu.privacy.title")
      assert privacy_item.url == "https://example.com/privacy.pdf"

      consent_item = Enum.find(vm.context_menu_items, &(&1.id == :consent))
      assert consent_item.label == dgettext("eyra-assignment", "context.menu.consent.title")

      support_item = Enum.find(vm.context_menu_items, &(&1.id == :assignment_helpdesk))
      assert support_item.label == dgettext("eyra-assignment", "context.menu.support.title")

      # Should have page refs
      assert vm.intro_page_ref.key == :assignment_information
      assert vm.support_page_ref.key == :assignment_helpdesk
    end

    test "builds minimal context menu when items missing", %{assignment: assignment, user: user} do
      # Assignment has no privacy_doc, no consent, no page_refs
      assigns = build_assigns(user, %{})
      vm = Assignment.CrewWorkViewBuilder.view_model(assignment, assigns)

      # Should have empty context menu
      assert vm.context_menu_items == []

      # Should have nil page refs
      assert vm.intro_page_ref == nil
      assert vm.support_page_ref == nil
    end

    test "includes user from assigns", %{assignment: assignment, user: user} do
      assigns = build_assigns(user, %{})
      vm = Assignment.CrewWorkViewBuilder.view_model(assignment, assigns)

      assert vm.user == user
    end
  end

  describe "view_model/2 with multiple work items" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment_with_multiple_tasks()
      assignment = Assignment.Factories.add_participant(assignment, user)

      %{user: user, assignment: assignment}
    end

    test "builds task list view with multiple work items", %{assignment: assignment, user: user} do
      assigns = build_assigns(user, %{})
      vm = Assignment.CrewWorkViewBuilder.view_model(assignment, assigns)

      # Should have task list view (not single)
      assert vm.task_view.implementation == Assignment.CrewTaskListView
      assert String.starts_with?(vm.task_view.id, "crew_task_list_view_")
    end
  end

  # Helper functions
  defp build_assigns(user, user_state) do
    live_context =
      Frameworks.Concept.LiveContext.new(%{
        current_user: user,
        timezone: "UTC",
        user_state: user_state,
        panel_info: nil
      })

    %{
      current_user: user,
      user_state: user_state,
      live_context: live_context
    }
  end
end
