defmodule Systems.Feldspar.ToolViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Feldspar

  describe "view_model/2" do
    setup do
      tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})

      %{tool: tool}
    end

    test "builds correct VM with all required fields", %{tool: tool} do
      assigns = build_assigns("Test App", :custom_icon)

      vm = Feldspar.ToolViewBuilder.view_model(tool, assigns)

      # Should have tool, title, and icon (icon normalized to lowercase string)
      assert vm.tool.id == tool.id
      assert vm.title == "Test App"
      assert vm.icon == "custom_icon"

      # Should have description
      assert vm.description == dgettext("eyra-feldspar", "tool.description")

      # Should have button
      assert vm.button.action.type == :send
      assert vm.button.action.event == "start"
      assert vm.button.face.type == :primary
      assert vm.button.face.label == dgettext("eyra-feldspar", "tool.button")

      # Should have app_view configured correctly
      assert vm.app_view.implementation == Systems.Feldspar.AppView
      assert vm.app_view.options[:key] == "feldspar_tool_#{tool.id}"
      assert vm.app_view.options[:url] == "https://example.com/app/index.html"
      assert vm.app_view.options[:locale] != nil
    end

    test "builds app_view with correct URL format", %{tool: tool} do
      assigns = build_assigns("Test App", :test_icon)

      vm = Feldspar.ToolViewBuilder.view_model(tool, assigns)

      # URL should append /index.html to archive_ref
      assert vm.app_view.options[:url] == "#{tool.archive_ref}/index.html"
    end

    test "handles nil icon", %{tool: tool} do
      assigns = build_assigns("Title", nil)
      vm = Feldspar.ToolViewBuilder.view_model(tool, assigns)
      assert vm.icon == nil
    end

    test "normalizes string icon to lowercase", %{tool: tool} do
      # Mixed case icon (as might be stored in database)
      assigns = build_assigns("Title", "TikTok")
      vm = Feldspar.ToolViewBuilder.view_model(tool, assigns)
      assert vm.icon == "tiktok"

      # Already lowercase
      assigns = build_assigns("Title", "apple")
      vm = Feldspar.ToolViewBuilder.view_model(tool, assigns)
      assert vm.icon == "apple"

      # All uppercase
      assigns = build_assigns("Title", "INSTAGRAM")
      vm = Feldspar.ToolViewBuilder.view_model(tool, assigns)
      assert vm.icon == "instagram"
    end
  end

  describe "upload_context participant" do
    setup do
      tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})
      %{tool: tool}
    end

    test "participant is included in upload_context when provided", %{tool: tool} do
      # participant is a declared dependency of Feldspar.ToolView
      # CrewTaskListViewBuilder computes it and passes through context
      assigns = %{
        title: "Test App",
        icon: :tiktok,
        assignment_id: 123,
        workflow_item_id: 456,
        participant: "user_public_id_abc123"
      }

      vm = Feldspar.ToolViewBuilder.view_model(tool, assigns)

      upload_context = vm.app_view.options[:upload_context]
      assert upload_context.participant == "user_public_id_abc123"

      filename = Feldspar.DataDonationFolder.filename(stringify_keys(upload_context))
      assert filename =~ "participant=user_public_id_abc123"
    end
  end

  # Helper functions
  defp build_assigns(title, icon) do
    %{
      title: title,
      icon: icon
    }
  end

  defp stringify_keys(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
