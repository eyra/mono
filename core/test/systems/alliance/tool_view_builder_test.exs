defmodule Systems.Alliance.ToolViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Alliance

  describe "view_model/2" do
    test "builds correct VM with title, description, and button" do
      tool = Factories.insert!(:alliance_tool, %{url: "https://external-tool.example.com"})

      assigns = %{
        title: "Test Alliance Survey",
        description: "This is a test description",
        url: "https://external-tool.example.com?participant=123"
      }

      vm = Alliance.ToolViewBuilder.view_model(tool, assigns)

      # Should have title and description from assigns
      assert vm.title == "Test Alliance Survey"
      assert vm.description == "This is a test description"

      # Should have button configured with url from assigns
      assert vm.button.action.type == :http_get
      assert vm.button.action.to == "https://external-tool.example.com?participant=123"
      assert vm.button.action.target == "_blank"
      assert vm.button.action.phx_event == "start_tool"
      assert vm.button.face.type == :primary
      assert vm.button.face.label == dgettext("eyra-alliance", "tool.button")
    end

    test "tool parameter is ignored - all data comes from assigns" do
      # Tool is passed but not used - Alliance is abstract
      tool = Factories.insert!(:alliance_tool, %{url: "https://ignored-url.example.com"})

      assigns = %{
        title: "Custom Title",
        description: "Custom Description",
        url: "https://actual-url.example.com"
      }

      vm = Alliance.ToolViewBuilder.view_model(tool, assigns)

      # URL should come from assigns, not from tool
      assert vm.button.action.to == "https://actual-url.example.com"
      assert vm.title == "Custom Title"
      assert vm.description == "Custom Description"
    end

    test "button opens url in new tab" do
      tool = Factories.insert!(:alliance_tool)

      assigns = %{
        title: "Survey",
        description: "Description",
        url: "https://survey.example.com"
      }

      vm = Alliance.ToolViewBuilder.view_model(tool, assigns)

      assert vm.button.action.target == "_blank"
    end

    test "button dispatches tool_started event" do
      tool = Factories.insert!(:alliance_tool)

      assigns = %{
        title: "Survey",
        description: "Description",
        url: "https://survey.example.com"
      }

      vm = Alliance.ToolViewBuilder.view_model(tool, assigns)

      assert vm.button.action.phx_event == "start_tool"
    end
  end
end
