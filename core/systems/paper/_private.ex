defmodule Systems.Paper.Private do
  import Systems.Paper.Queries
  import Ecto.Query, only: [last: 2]

  alias Core.Repo
  alias Systems.Version

  def obtain_version!(nil, nil, _paper_set) do
    obtain_version!(nil)
  end

  def obtain_version!(nil, title, paper_set) do
    obtain_version!(get_paper_by_title(title, paper_set))
  end

  def obtain_version!(doi, _, paper_set) do
    paper = get_paper_by_doi(doi, paper_set, [:version])
    obtain_version!(paper)
  end

  def obtain_version!(%{version: %Version.Model{} = version}) do
    Version.Public.prepare_new(version)
    |> Repo.insert!()
  end

  def obtain_version!(_) do
    Version.Public.prepare_first()
    |> Repo.insert!()
  end

  def get_paper_by_doi(doi, paper_set, preload \\ []) do
    paper_query_by_doi(doi, paper_set)
    |> last(:inserted_at)
    |> Repo.one()
    |> Repo.preload(preload)
  end

  def get_paper_by_title(title, paper_set) do
    paper_query_by_title(title, paper_set)
    |> last(:inserted_at)
    |> Repo.one()
    |> Repo.preload(:version)
  end
end
