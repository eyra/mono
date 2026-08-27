defmodule Systems.Storage.BuiltIn.Backend do
  @moduledoc false
  @behaviour Systems.Storage.Backend

  alias Systems.Storage.BuiltIn

  require Logger

  @impl true
  def store(%{"key" => folder}, data, %{"identifier" => identifier}) do
    filename = filename(identifier)
    special().store(folder, filename, data)
  end

  @impl true
  def store(_, _, _) do
    {:error, :endpoint_key_missing}
  end

  @impl true
  def list_files(%{key: folder}) do
    special().list_files(folder)
  end

  @impl true
  def delete_files(%{key: folder}) do
    special().delete_files(folder)
  end

  @impl true
  def connected?(_endpoint) do
    # Always connected, no account settings in endpoint model
    true
  end

  @impl true
  def filename(identifier), do: Systems.Storage.Filename.generate(identifier)

  defp settings do
    Application.fetch_env!(:core, BuiltIn)
  end

  defp special do
    # Allow mocking
    Access.get(settings(), :special, BuiltIn.LocalFS)
  end
end
