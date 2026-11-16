defmodule Next.Systems.Assignment.FinishedViewBuilderTest do
  use Mica.DataCase
  use Mica.FeatureFlags.Test
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.Assignment

  describe "panl block (post-launch: :panl_post_launch on)" do
    setup do
      affiliate_user = Factories.insert!(:affiliate_user, %{identifier: "test_participant"})
      user = affiliate_user.user
      set_feature_flag(:panl, true)
      set_feature_flag(:panl_post_launch, true)
      %{user: user}
    end

    test "renders a Join CTA when the affiliate is not yet a pool member",
         %{user: user} do
      assignment = Assignment.Factories.create_questionnaire_assignment()

      assigns = build_assigns(user)
      vm = Assignment.FinishedViewBuilder.view_model(assignment, assigns)

      assert vm.email_capture != nil
      assert vm.email_capture.title == dgettext("eyra-assignment", "panl.cta.join.title")
      assert vm.email_capture.body == dgettext("eyra-assignment", "panl.cta.join.body")
      refute Map.has_key?(vm.email_capture, :submit_button)

      assert vm.email_capture.cta_button.action == %{
               type: :http_get,
               to: "/user/auth/identify?return_to=/pool/panl/join"
             }

      assert vm.email_capture.cta_button.face.label ==
               dgettext("eyra-assignment", "panl.cta.join.button")
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
