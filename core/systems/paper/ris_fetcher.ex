defmodule Systems.Paper.RISFetcher do
  @moduledoc """
  Behaviour for fetching RIS file content from external sources.

  Focused purely on fetching content from various sources like HTTP, file system,
  cloud storage, etc. Does not handle database operations.
  """

  alias Systems.Paper

  @doc """
  Fetch RIS content from a reference file.

  Takes a reference file model and fetches the actual RIS content from wherever
  it's stored (URL, file path, cloud storage, etc.).
  """
  @callback fetch_content(Paper.ReferenceFileModel.t()) :: {:ok, binary()} | {:error, String.t()}
end
