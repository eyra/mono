defmodule Systems.Paper.RISFetcherBackendStream do
  @moduledoc """
  Streaming fetcher that uses the configured storage backend.
  This is the recommended approach as it respects the application's storage configuration.
  """

  alias Systems.Paper

  @doc """
  Stream RIS content using the configured storage backend.
  The backend is determined by the application configuration, not the URL.
  """
  def fetch_content(%Paper.ReferenceFileModel{file: %{ref: nil}}) do
    {:error, "Reference file URL is missing"}
  end

  def fetch_content(%Paper.ReferenceFileModel{file: %{ref: ref}}) do
    # Get the configured content backend
    backend = get_content_backend()

    # Use the backend's streaming capability
    backend.stream(ref)
  end

  def fetch_content(%Paper.ReferenceFileModel{file: %Ecto.Association.NotLoaded{}}) do
    {:error, "Reference file is not loaded"}
  end

  # Get the configured content backend module
  defp get_content_backend do
    config = Application.fetch_env!(:core, :content)
    Keyword.fetch!(config, :backend)
  end
end
