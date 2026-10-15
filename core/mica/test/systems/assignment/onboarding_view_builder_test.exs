defmodule Systems.Assignment.OnboardingViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment
  alias Systems.Content

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_base_assignment()

      %{user: user, assignment: assignment}
    end

    test "builds correct VM when intro page exists", %{assignment: assignment, user: user} do
      # Add an intro page_ref
      page = Factories.insert!(:content_page)

      _page_ref =
        Factories.insert!(:assignment_page_ref, %{
          assignment: assignment,
          page: page,
          key: :assignment_information
        })

      assignment = Repo.preload(assignment, [page_refs: :page], force: true)

      assigns = build_assigns(user)
      vm = Assignment.OnboardingViewBuilder.view_model(assignment, assigns)

      # Should have page_ref with assignment_id
      assert vm.page_ref.assignment_id == assignment.id
      assert vm.page_ref.key == :assignment_information

      # Should have user
      assert vm.user == user

      # Should have content_page configured
      assert vm.content_page != nil
      assert vm.content_page.module == Content.PageView
      assert vm.content_page.id == :content_page
      assert vm.content_page.title == dgettext("eyra-assignment", "onboarding.intro.title")
      assert vm.content_page.page.id == page.id

      # Should have continue button
      assert vm.continue_button.action.type == :send
      assert vm.continue_button.action.event == "continue"
      assert vm.continue_button.face.type == :primary

      assert vm.continue_button.face.label ==
               dgettext("eyra-assignment", "onboarding.continue.button")
    end

    test "builds correct VM when no intro page exists", %{assignment: assignment, user: user} do
      # No page_ref added, so assignment has empty page_refs
      assignment = Repo.preload(assignment, [:page_refs], force: true)

      assigns = build_assigns(user)
      vm = Assignment.OnboardingViewBuilder.view_model(assignment, assigns)

      # Should have page_ref with assignment_id but no other data
      assert vm.page_ref.assignment_id == assignment.id
      refute Map.has_key?(vm.page_ref, :key)

      # Should have user
      assert vm.user == user

      # Should NOT have content_page
      assert vm.content_page == nil

      # Should still have continue button
      assert vm.continue_button.action.event == "continue"
    end
  end

  # Helper functions
  defp build_assigns(user) do
    %{
      current_user: user,
      timezone: "UTC"
    }
  end
end
