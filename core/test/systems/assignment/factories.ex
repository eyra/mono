defmodule Systems.Assignment.Factories do
  alias Core.Factories

  alias Systems.Alliance
  alias Systems.Budget

  def create_info(duration, subject_count) do
    Factories.insert!(
      :assignment_info,
      %{
        subject_count: subject_count,
        duration: duration,
        language: :en,
        devices: [:desktop]
      }
    )
  end

  def create_tool(auth_node) do
    Factories.insert!(:alliance_tool, %{
      url: "https://eyra.co/alliance/123",
      auth_node: auth_node,
      director: :assignment
    })
  end

  def create_tool_ref(%Alliance.ToolModel{} = tool) do
    Factories.insert!(:tool_ref, %{
      alliance_tool: tool
    })
  end

  def create_workflow() do
    Factories.insert!(:workflow, %{})
  end

  def create_workflow_item(workflow, tool_ref) do
    Factories.insert!(:workflow_item, %{
      workflow: workflow,
      tool_ref: tool_ref
    })
  end

  def create_assignment(info, workflow, auth_node, %Budget.Model{} = budget) do
    crew = Factories.insert!(:crew)

    Factories.insert!(:assignment, %{
      info: info,
      workflow: workflow,
      crew: crew,
      auth_node: auth_node,
      budget: budget
    })
  end

  def create_assignment(info, workflow, auth_node, status) when is_atom(status) do
    crew = Factories.insert!(:crew)

    Factories.insert!(:assignment, %{
      info: info,
      workflow: workflow,
      crew: crew,
      auth_node: auth_node,
      special: :data_donation,
      status: status
    })
  end

  def create_assignment(duration, subject_count, status \\ :online) when is_integer(duration) do
    assignment_auth_node = Factories.build(:auth_node)
    tool_auth_node = Factories.build(:auth_node, %{parent: assignment_auth_node})

    info = create_info(Integer.to_string(duration), subject_count)
    tool = create_tool(tool_auth_node)
    tool_ref = create_tool_ref(tool)
    workflow = create_workflow()
    _workflow_item = create_workflow_item(workflow, tool_ref)

    create_assignment(info, workflow, assignment_auth_node, status)
  end

  def build_assignment() do
    Factories.insert!(:assignment, %{})
  end
end
