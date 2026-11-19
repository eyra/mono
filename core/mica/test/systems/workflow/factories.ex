defmodule Systems.Workflow.Factories do
  alias Mica.Factories
  alias Systems.Document
  alias Systems.Feldspar

  def create_tool() do
    Factories.insert!(:document_tool, %{
      director: :assignment
    })
  end

  def create_tool_ref(%Document.ToolModel{} = tool, special) do
    Factories.insert!(:tool_ref, %{
      special: special,
      document_tool: tool
    })
  end

  def create_tool_ref(%Feldspar.ToolModel{} = tool, special) do
    Factories.insert!(:tool_ref, %{
      special: special,
      feldspar_tool: tool
    })
  end

  def create_workflow() do
    Factories.insert!(:workflow, %{})
  end

  def create_item(workflow, tool_ref, index) do
    Factories.insert!(:workflow_item, %{
      workflow: workflow,
      tool_ref: tool_ref,
      position: index
    })
  end
end
