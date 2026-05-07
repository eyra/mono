defmodule Systems.Zircon.Queries do
  import Ecto.Query
  require Frameworks.Utility.Query

  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Account
  alias Systems.Annotation
  alias Systems.Paper
  alias Systems.Zircon

  # SCREENING TOOL MODEL

  def screening_tool_query() do
    from(t in Zircon.Screening.ToolModel, as: :zircon_screening_tool)
  end

  def screening_tool_query(%Paper.ReferenceFileModel{id: reference_file_id}) do
    build(screening_tool_query(), :zircon_screening_tool,
      reference_files: [id == ^reference_file_id]
    )
  end

  # SCREENING TOOL REFERENCE FILE ASSOC

  def screening_tool_reference_file_query() do
    from(trf in Zircon.Screening.ToolReferenceFileAssoc, as: :screening_tool_reference_file)
  end

  def screening_tool_reference_file_query(%Zircon.Screening.ToolModel{id: tool_id}) do
    build(screening_tool_reference_file_query(), :screening_tool_reference_file,
      tool: [id == ^tool_id],
      reference_file: [status != :archived]
    )
  end

  # SCREENING TOOL ANNOTATION ASSOC

  def screening_tool_annotation_assoc_query() do
    from(taa in Zircon.Screening.ToolAnnotationAssoc, as: :screening_tool_annotation_assoc)
  end

  def screening_tool_annotation_assoc_query(%Zircon.Screening.ToolModel{id: tool_id}) do
    build(screening_tool_annotation_assoc_query(), :screening_tool_annotation_assoc,
      tool: [id == ^tool_id]
    )
  end

  def screening_tool_annotation_assoc_query(%Annotation.Model{id: annotation_id}) do
    build(screening_tool_annotation_assoc_query(), :screening_tool_annotation_assoc, [
      annotation_id == ^annotation_id
    ])
  end

  # SCREENING SESSION

  def screening_session_query() do
    from(s in Zircon.Screening.SessionModel, as: :screening_session)
  end

  def screening_session_query(%Zircon.Screening.ToolModel{id: tool_id}) do
    build(screening_session_query(), :screening_session, tool: [id == ^tool_id])
  end

  def screening_session_query(tool, %Account.User{id: user_id}) do
    build(screening_session_query(tool), :screening_session, user: [id == ^user_id])
  end
end
