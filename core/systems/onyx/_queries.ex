defmodule Systems.Onyx.Queries do
  import Ecto.Query
  require Frameworks.Utility.Query

  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Onyx

  # TOOL
  def tool_query() do
    from(t in Onyx.ToolModel, as: :tool)
  end

  # TOOL FILE ASSOCIATION
  def tool_file_query() do
    from(tf in Onyx.ToolFileAssociation, as: :tool_file)
  end

  def tool_file_query(%Onyx.ToolModel{id: tool_id}, exclude \\ [:archived]) do
    build(tool_file_query(), :tool_file, tool: [id == ^tool_id])
    |> tool_file_exclude(exclude)
  end

  def tool_file_exclude(query, exclude) when is_list(exclude) do
    where(query, [tool_file: tf], tf.status not in ^exclude)
  end

  # FILE PAPER ASSOCIATION
  def file_paper_query() do
    from(Onyx.FilePaperAssociation, as: :file_paper)
  end

  def file_paper_query(%Onyx.ToolModel{id: tool_id}) do
    build(file_paper_query(), :file_paper,
      file: [
        tool: [id == ^tool_id]
      ]
    )
  end
end
