defmodule Systems.Paper.Queries do
  import Ecto.Query
  require Frameworks.Utility.Query

  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Paper

  # PAPER
  def paper_query() do
    from(p in Paper.Model, as: :paper)
  end

  def paper_query(%Paper.ReferenceFileModel{id: reference_file_id}) do
    paper_query()
    |> join(:inner, [paper: p], rf in Paper.ReferenceFilePaperAssoc,
      on: rf.paper_id == p.id,
      as: :reference_file_paper
    )
    |> where([reference_file_paper: rf], rf.reference_file_id == ^reference_file_id)
  end

  def paper_query_by_title(title, %Paper.SetModel{id: paper_set_id}) do
    build(paper_query(), :paper, [
      title == ^title,
      sets: [id == ^paper_set_id]
    ])
  end

  def paper_query_by_doi(doi, %Paper.SetModel{id: paper_set_id}) do
    build(paper_query(), :paper, [
      doi == ^doi,
      sets: [id == ^paper_set_id]
    ])
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

  # Paper set
  def paper_set_query() do
    from(s in Paper.SetModel, as: :set)
  end

  def paper_set_query(category) do
    paper_set_query()
    |> where([set: s], s.category == ^category)
  end

  def paper_set_query(category, identifier) do
    paper_set_query(category)
    |> where([set: s], s.identifier == ^identifier)
  end
end
