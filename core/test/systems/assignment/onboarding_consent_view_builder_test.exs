defmodule Systems.Assignment.OnboardingConsentViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment
  alias Systems.Consent

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment_with_consent()

      %{user: user, assignment: assignment}
    end

    test "builds correct VM with consent agreement", %{assignment: assignment, user: user} do
      assigns = build_assigns(user)
      vm = Assignment.OnboardingConsentViewBuilder.view_model(assignment, assigns)

      # Should have title
      assert vm.title == dgettext("eyra-assignment", "onboarding.consent.title")

      # Should have user
      assert vm.user == user

      # Should have revision
      assert vm.revision.agreement_id == assignment.consent_agreement.id

      # Should have clickwrap_view configured
      assert vm.clickwrap_view.module == Consent.ClickWrapView
      assert vm.clickwrap_view.id == :clickwrap_view
      assert vm.clickwrap_view.revision.id == vm.revision.id
      assert vm.clickwrap_view.user == user
      assert vm.clickwrap_view.accept_text == dgettext("eyra-consent", "click_wrap.accept.button")

      assert vm.clickwrap_view.decline_text ==
               dgettext("eyra-consent", "click_wrap.decline.button")

      assert vm.clickwrap_view.validation_text ==
               dgettext("eyra-consent", "click_wrap.consent.validation")
    end

    test "uses latest revision from consent agreement", %{assignment: assignment, user: user} do
      # Create an additional revision
      consent_agreement = assignment.consent_agreement
      _newer_revision = Factories.insert!(:consent_revision, %{agreement: consent_agreement})

      # Reload assignment to get updated revisions
      assignment = Repo.preload(assignment, [consent_agreement: :revisions], force: true)

      assigns = build_assigns(user)
      vm = Assignment.OnboardingConsentViewBuilder.view_model(assignment, assigns)

      # Should use the latest (newest) revision
      all_revisions = assignment.consent_agreement.revisions
      latest_revision = Enum.max_by(all_revisions, & &1.id)

      assert vm.revision.id == latest_revision.id
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
