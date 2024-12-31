defmodule Systems.Paper.Queries do
  import Ecto.Query
  require Frameworks.Utility.Query

  #import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Paper

  # PAPER
  def paper_query() do
    from(p in Paper.Model, as: :paper)
  end

  # REFERENCE FILE
  def reference_file_query() do
    from(tf in Paper.ReferenceFileModel, as: :reference_file)
  end

  def reference_file_exclude(query, exclude) when is_list(exclude) do
    where(query, [reference_file: rf], rf.status not in ^exclude)
  end

  def reference_file_paper_query() do
    from(Paper.ReferenceFilePaperAssoc, as: :reference_file_paper)
  end

end
