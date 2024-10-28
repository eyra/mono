defmodule Systems.Onyx.Queries do
  import Ecto.Query
  alias Systems.Onyx

  def tool_query() do
    from(tool in Onyx.ToolModel)
  end
end
