defmodule Systems.Feldspar.ToolViewBuilderTest do
  use Core.DataCase

  alias Systems.Feldspar

  describe "view_model/2" do
    setup do
      tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})

      %{tool: tool}
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
      assigns =
        build_assigns("Test App", :tiktok)
        |> Map.merge(%{
          assignment_id: 123,
          workflow_item_id: 456,
          participant: "user_public_id_abc123"
        })

      vm = Feldspar.ToolViewBuilder.view_model(tool, assigns)

      upload_context = vm.app_view.options[:upload_context]

      filename = Feldspar.DataDonationFolder.filename(stringify_keys(upload_context))
      assert filename =~ "participant=user_public_id_abc123"
    end
  end

  # Helper functions
  defp build_assigns(title, icon) do
    %{
      title: title,
      icon: icon,
      recovery: %{
        scope: "opaque-execution-scope",
        on_entry: :check
      }
    }
  end

  defp stringify_keys(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
