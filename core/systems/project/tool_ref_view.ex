defmodule Systems.Project.ToolRefView do
  use CoreWeb, :html

  alias Frameworks.Concept

  alias Systems.{
    Project
  }

  defp get_tool(tool_ref), do: Project.ToolRefModel.tool(tool_ref)
  defp get_work(tool), do: Concept.ToolModel.launcher(tool)

  attr(:tool_ref, :map, required: true)
  attr(:task, :map, required: true)

  def tool_ref_view(%{tool_ref: tool_ref} = assigns) do
    assigns =
      tool_ref
      |> get_tool()
      |> get_work()
      |> then(&assign(assigns, :work, &1))

    ~H"""
    <div class="w-full h-full">
      <.function_component function={@work.function} props={@work.props}  />
    </div>
    """
  end
end
