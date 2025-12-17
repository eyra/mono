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

      # Should have tool, title, and icon
      assert vm.tool.id == tool.id
      assert vm.title == "Test App"
      assert vm.icon == :custom_icon

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

    test "handles different icon types", %{tool: tool} do
      # Test with atom icon
      assigns = build_assigns("Title", :home)
      vm = Feldspar.ToolViewBuilder.view_model(tool, assigns)
      assert vm.icon == :home

      # Test with string icon
      assigns = build_assigns("Title", "settings")
      vm = Feldspar.ToolViewBuilder.view_model(tool, assigns)
      assert vm.icon == "settings"

      # Test with nil icon
      assigns = build_assigns("Title", nil)
      vm = Feldspar.ToolViewBuilder.view_model(tool, assigns)
      assert vm.icon == nil
    end
  end

  # Helper functions
  defp build_assigns(title, icon) do
    %{
      title: title,
      icon: icon
    }
  end
end
