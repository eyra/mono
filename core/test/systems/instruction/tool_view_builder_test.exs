defmodule Systems.Instruction.ToolViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.{Instruction, Content}

  describe "view_model/2" do
    setup do
      auth_node = Factories.insert!(:auth_node)
      tool = Repo.insert!(%Instruction.ToolModel{auth_node_id: auth_node.id})
      page = Factories.insert!(:content_page)

      # Create instruction page reference
      _instruction_page =
        Repo.insert!(%Instruction.PageModel{
          tool_id: tool.id,
          page_id: page.id
        })

      tool = Repo.preload(tool, [pages: :page], force: true)

      %{tool: tool, page: page}
    end

    test "builds correct VM when tool has pages", %{tool: tool, page: page} do
      assigns = %{}

      vm = Instruction.ToolViewBuilder.view_model(tool, assigns)

      # Should have tool and page
      assert vm.tool.id == tool.id
      assert vm.page.id == page.id

      # Should have page_view configured
      assert vm.page_view.module == Content.PageView
      assert vm.page_view.id == :page_view
      assert vm.page_view.title == dgettext("eyra-instruction", "page.title")
      assert vm.page_view.page.id == page.id

      # Should have done button
      assert vm.done_button.action.type == :send
      assert vm.done_button.action.event == "done"
      assert vm.done_button.face.type == :primary
      assert vm.done_button.face.label == dgettext("eyra-ui", "done.button")
    end

    test "handles tool with no pages" do
      # Create tool without pages
      auth_node = Factories.insert!(:auth_node)
      tool = Repo.insert!(%Instruction.ToolModel{auth_node_id: auth_node.id})
      tool = Repo.preload(tool, [:pages], force: true)

      assigns = %{}
      vm = Instruction.ToolViewBuilder.view_model(tool, assigns)

      # Should have nil page and page_view
      assert vm.page == nil
      assert vm.page_view == nil

      # Should still have done button
      assert vm.done_button.action.event == "done"
    end

    test "handles tool with multiple pages - uses first page" do
      auth_node = Factories.insert!(:auth_node)
      tool = Repo.insert!(%Instruction.ToolModel{auth_node_id: auth_node.id})
      page1 = Factories.insert!(:content_page)
      page2 = Factories.insert!(:content_page)

      # Create two instruction pages
      Repo.insert!(%Instruction.PageModel{
        tool_id: tool.id,
        page_id: page1.id
      })

      Repo.insert!(%Instruction.PageModel{
        tool_id: tool.id,
        page_id: page2.id
      })

      tool = Repo.preload(tool, [pages: :page], force: true)

      assigns = %{}
      vm = Instruction.ToolViewBuilder.view_model(tool, assigns)

      # Should use the first page in the list
      assert vm.page.id in [page1.id, page2.id]
      assert vm.page_view.page.id == vm.page.id
    end
  end
end
