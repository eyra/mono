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

  describe "email_capture" do
    setup do
      affiliate_user = Factories.insert!(:affiliate_user, %{identifier: "test_participant"})
      user = affiliate_user.user
      %{user: user}
    end

    test "includes email_capture for questionnaire assignment", %{user: user} do
      assignment = Assignment.Factories.create_questionnaire_assignment()

      assigns = build_assigns(user)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      assert vm.email_capture != nil
      assert vm.email_capture.action == {:add_to_pool, :panl}
      assert vm.email_capture.title != nil
      assert vm.email_capture.body != nil
      assert vm.email_capture.email_label != nil
      assert vm.email_capture.submit_button.action.type == :submit
      assert vm.email_capture.submit_button.face.type == :primary
    end

    test "email_capture is nil for non-affiliate user on questionnaire assignment", %{} do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_questionnaire_assignment()

      assigns = build_assigns(user)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      assert vm.email_capture == nil
    end

    test "email_capture is nil for non-questionnaire assignment", %{user: user} do
      assignment = Assignment.Factories.create_assignment_with_affiliate(nil)

      assigns = build_assigns(user)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      assert vm.email_capture == nil
    end

    test "email_capture shows success when user is already a pool member", %{user: user} do
      assignment = Assignment.Factories.create_questionnaire_assignment()
      panl_pool = Systems.Pool.Assembly.get_or_create_panl()
      Systems.Pool.Public.add_participant!(panl_pool, user)

      assigns = build_assigns(user)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      assert vm.email_capture != nil
      assert vm.email_capture.title != nil
      assert vm.email_capture.body != nil
      refute Map.has_key?(vm.email_capture, :submit_button)
    end

    test "email_capture is nil when consent declined", %{} do
      user = Factories.insert!(:member)
      consent_agreement = Factories.insert!(:consent_agreement)
      _revision = Factories.insert!(:consent_revision, %{agreement: consent_agreement})

      auth_node = Factories.insert!(:auth_node)
      tool_auth_node = Factories.insert!(:auth_node, %{parent: auth_node})

      tool = Assignment.Factories.create_tool(tool_auth_node)
      tool_ref = Assignment.Factories.create_tool_ref(tool)
      workflow = Assignment.Factories.create_workflow()
      _item = Assignment.Factories.create_workflow_item(workflow, tool_ref)
      info = Assignment.Factories.create_info("10", 100)
      crew = Factories.insert!(:crew)

      assignment =
        Factories.insert!(:assignment, %{
          info: info,
          consent_agreement: consent_agreement,
          workflow: workflow,
          crew: crew,
          auth_node: auth_node,
          special: :questionnaire,
          status: :online
        })
        |> Core.Repo.preload(Systems.Assignment.Model.preload_graph(:down))
        |> Assignment.Factories.add_participant(user)

      Assignment.Public.decline_member(assignment, user)

      assigns = build_assigns(user)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      assert vm.email_capture == nil
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
