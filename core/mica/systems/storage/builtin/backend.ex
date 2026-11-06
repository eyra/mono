defmodule Systems.Storage.BuiltIn.Backend do
  @behaviour Systems.Storage.Backend

  require Logger

  alias Systems.Storage.BuiltIn

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
    Mica.Env.fetch!(Systems.Storage.BuiltIn)
  end

  @doc """
  Refuses to start while LocalFS donations from an earlier version are still in
  `upload_path` (see `BuiltIn.LocalFS.check_upload_path!/2`). Runs at application
  start, not in the runtime config: `prod-migrate` evaluates that config without
  the S3 settings, so it would look like LocalFS.
  """
  def check_upload_path! do
    if special() == BuiltIn.LocalFS do
      BuiltIn.LocalFS.check_upload_path!(Mica.Env.get(:upload_path))
    end

    :ok
  end

  defp special do
    # Allow mocking
    Access.get(settings(), :special, BuiltIn.LocalFS)
  end
end
