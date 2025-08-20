defmodule Systems.Paper.RISFetcherHTTP do
  @moduledoc """
  HTTP implementation of RISFetcher that fetches content via HTTP requests.

  Focused purely on fetching RIS content from HTTP URLs. Does not handle
  database operations - those should be done by the caller.
  """

  @behaviour Systems.Paper.RISFetcher

  alias Systems.Paper

  @doc """
  Fetch RIS content from a reference file via HTTP.

  Expects the reference file to have a file.ref URL to fetch from.
  """
  def fetch_content(%Paper.ReferenceFileModel{file: %{ref: nil}}) do
    {:error, "Reference file URL is missing"}
  end

  def fetch_content(%Paper.ReferenceFileModel{file: %{ref: ref}}) do
    fetch_from_url(ref)
  end

  def fetch_content(%Paper.ReferenceFileModel{file: %Ecto.Association.NotLoaded{}}) do
    {:error, "Reference file is not loaded"}
  end

  # Private functions

  defp fetch_from_url(url) do
    with {:ok, _, _, client_ref} <- :hackney.request(:get, url),
         {:ok, body} <- :hackney.body(client_ref) do
      {:ok, body}
    else
      error -> {:error, "Failed to fetch file from URL: #{inspect(error)}"}
    end
  end
end
