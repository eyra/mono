defprotocol Core.Persister do
  @fallback_to_any true
  @spec save(any, map) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def save(state, changeset)
end

defimpl Core.Persister, for: Any do
  require Logger

  def save(_any, changeset) do
    Logger.warning("falling back to any persister")
    Core.Repo.update(changeset)
  end
end
