defmodule Systems.Instruction.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Instruction
  alias Systems.Content

  def tool_query() do
    from(Instruction.ToolModel, as: :tool)
  end

  def tool_query(%Content.PageModel{id: content_page_id}) do
    build(tool_query(), :tool,
      pages: [
        page_id == ^content_page_id
      ]
    )
  end
end
