defmodule Systems.Assignment.FinishedViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_base_assignment()

      %{user: user, assignment: assignment}
    end

    test "builds correct VM for normal completion without redirect", %{user: user} do
      assignment = Assignment.Factories.create_assignment_with_affiliate(nil)

      assigns = build_assigns(user)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      # Should have illustration and retry button
      assert vm.illustration == "/images/illustrations/finished.svg"
      assert vm.back_button.action.type == :send
      assert vm.back_button.action.event == "retry"
      assert vm.back_button.face.icon == :back
      assert vm.continue_button == nil

      # Should use normal title and body
      assert vm.title == dgettext("eyra-assignment", "finished_view.title")
      assert vm.body == dgettext("eyra-assignment", "finished_view.body")
    end

    test "builds correct VM with redirect URL", %{user: user} do
      redirect_url = "https://example.com/return"

      assignment =
        Assignment.Factories.create_assignment_with_affiliate(redirect_url)
        |> Assignment.Factories.add_affiliate_user(user)

      assigns = build_assigns(user, redirect_url)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      # Should NOT have illustration
      assert vm.illustration == nil

      # Should have redirect button
      assert vm.continue_button != nil
      assert vm.continue_button.action.type == :http_get
      assert vm.continue_button.action.to =~ "https://example.com/return"
      assert vm.continue_button.face.type == :primary

      # Should use redirect-specific body
      assert vm.body == dgettext("eyra-assignment", "finished_view.body.redirect")
    end

    test "builds correct VM for declined consent without redirect", %{user: user} do
      assignment =
        Assignment.Factories.create_assignment_with_consent_and_affiliate(nil)
        |> Assignment.Factories.add_participant(user)

      Assignment.Public.decline_member(assignment, user)

      assigns = build_assigns(user)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      # Should NOT have illustration
      assert vm.illustration == nil

      # Should have retry button
      assert vm.back_button.action.event == "retry"

      # Should NOT have redirect button
      assert vm.continue_button == nil

      # Should use declined title and body
      assert vm.title == dgettext("eyra-assignment", "finished_view.title.declined")
      assert vm.body == dgettext("eyra-assignment", "finished_view.body.declined")
    end

    test "builds correct VM for declined consent with redirect", %{user: user} do
      redirect_url = "https://example.com/return"

      assignment =
        Assignment.Factories.create_assignment_with_consent_and_affiliate(redirect_url)
        |> Assignment.Factories.add_affiliate_user(user)
        |> Assignment.Factories.add_participant(user)

      Assignment.Public.decline_member(assignment, user)

      assigns = build_assigns(user, redirect_url)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      # Should NOT have illustration (declined + redirect)
      assert vm.illustration == nil

      # Should have retry button
      assert vm.back_button.action.event == "retry"

      # Should have redirect button
      assert vm.continue_button != nil
      assert vm.continue_button.action.type == :http_get
      assert vm.continue_button.action.to =~ "https://example.com/return"

      # Should use declined + redirect body
      assert vm.title == dgettext("eyra-assignment", "finished_view.title.declined")
      assert vm.body == dgettext("eyra-assignment", "finished_view.body.declined.redirect")
    end

    test "builds correct VM with redirect URL and platform_name", %{user: user} do
      platform_name = "Acme Research Panel"
      redirect_url = "https://example.com/return"

      assignment =
        Assignment.Factories.create_assignment_with_affiliate(redirect_url, platform_name)
        |> Assignment.Factories.add_affiliate_user(user)

      assigns = build_assigns(user, redirect_url)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      # Should NOT have illustration
      assert vm.illustration == nil

      # Should have redirect button
      assert vm.continue_button != nil
      assert vm.continue_button.action.type == :http_get
      assert vm.continue_button.action.to =~ "https://example.com/return"

      # Should use platform-specific body with interpolated name
      expected_body =
        dgettext("eyra-assignment", "finished_view.body.redirect.platform",
          platform: platform_name
        )

      assert vm.body == expected_body
      assert vm.body =~ platform_name
    end

    test "builds correct VM for declined consent with redirect and platform_name", %{user: user} do
      platform_name = "Acme Research Panel"
      redirect_url = "https://example.com/return"

      assignment =
        Assignment.Factories.create_assignment_with_consent_and_affiliate(
          redirect_url,
          platform_name
        )
        |> Assignment.Factories.add_affiliate_user(user)
        |> Assignment.Factories.add_participant(user)

      Assignment.Public.decline_member(assignment, user)

      assigns = build_assigns(user, redirect_url)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      # Should NOT have illustration (declined + redirect)
      assert vm.illustration == nil

      # Should have retry button
      assert vm.back_button.action.event == "retry"

      # Should have redirect button
      assert vm.continue_button != nil
      assert vm.continue_button.action.type == :http_get
      assert vm.continue_button.action.to =~ "https://example.com/return"

      # Should use declined + redirect + platform body with interpolated name
      assert vm.title == dgettext("eyra-assignment", "finished_view.title.declined")

      expected_body =
        dgettext("eyra-assignment", "finished_view.body.declined.redirect.platform",
          platform: platform_name
        )

      assert vm.body == expected_body
      assert vm.body =~ platform_name
    end

    test "uses non-platform body when platform_name is empty string", %{user: user} do
      redirect_url = "https://example.com/return"

      assignment =
        Assignment.Factories.create_assignment_with_affiliate(redirect_url, "")
        |> Assignment.Factories.add_affiliate_user(user)

      assigns = build_assigns(user, redirect_url)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      # Should use regular redirect body (not platform-specific)
      assert vm.body == dgettext("eyra-assignment", "finished_view.body.redirect")
    end

    test "uses non-platform body when platform_name is nil", %{user: user} do
      redirect_url = "https://example.com/return"

      assignment =
        Assignment.Factories.create_assignment_with_affiliate(redirect_url, nil)
        |> Assignment.Factories.add_affiliate_user(user)

      assigns = build_assigns(user, redirect_url)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      # Should use regular redirect body (not platform-specific)
      assert vm.body == dgettext("eyra-assignment", "finished_view.body.redirect")
    end
  end

  # Helper functions
  defp build_assigns(user, redirect_url \\ nil) do
    %{
      current_user: user,
      timezone: "UTC",
      live_context: %{data: %{panel_info: %{redirect_url: redirect_url}}}
    }
  end
end
