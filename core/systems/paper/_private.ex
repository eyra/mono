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

  @doc """
  Centralized function to check if a paper exists in the database.
  Returns {:existing, paper} if found, :new if not found.

  Logic:
  - If paper has a DOI: check only by DOI (different DOIs = different papers)
  - If paper has no DOI: check by title
  """
  def check_paper_exists(%{doi: doi}, paper_set) when is_binary(doi) and doi != "" do
    if paper = get_paper_by_doi(doi, paper_set, [:version]) do
      {:existing, paper}
    else
      # If paper has a DOI but it's not in the database, it's a new paper
      # Don't check by title - different DOIs mean different papers
      :new
    end
  end

  def check_paper_exists(%{title: title}, paper_set) when is_binary(title) and title != "" do
    if paper = get_paper_by_title(title, paper_set) do
      {:existing, paper}
    else
      :new
    end
  end

  def check_paper_exists(_attrs, _paper_set), do: :new

  @doc """
  Checks if a paper matches another based on DOI or title.
  Used for detecting duplicates within a file.
  Returns true if papers match, false otherwise.
  """
  def papers_match?(%{doi: doi1} = _paper1, %{doi: doi2} = _paper2)
      when is_binary(doi1) and doi1 != "" and is_binary(doi2) and doi2 != "" do
    # If both have DOIs, compare DOIs
    normalized1 = normalize_doi(doi1)
    normalized2 = normalize_doi(doi2)
    normalized1 == normalized2
  end

  def papers_match?(%{title: title1} = _paper1, %{title: title2} = _paper2) do
    # If no DOIs or only one has DOI, compare by title
    normalized1 = normalize_title(title1)
    normalized2 = normalize_title(title2)
    normalized1 == normalized2
  end

  def papers_match?(_paper1, _paper2), do: false

  # Normalize DOI for comparison (remove common prefixes and clean up)
  # Note: This function is only called when doi is a non-empty binary
  defp normalize_doi(doi) when is_binary(doi) do
    doi
    |> String.downcase()
    |> String.replace(~r{^https?://doi.org/}, "")
    |> String.replace(~r{^doi:}, "")
    |> String.trim()
  end

  # Normalize title for comparison (lowercase, remove extra spaces)
  defp normalize_title(nil), do: nil
  defp normalize_title(""), do: nil

  defp normalize_title(title) when is_binary(title) do
    title
    |> String.downcase()
    |> String.replace(~r{\s+}, " ")
    |> String.trim()
  end
end
