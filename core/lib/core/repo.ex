defmodule Core.Repo do
  use Ecto.Repo,
    otp_app: :core,
    adapter: Ecto.Adapters.Postgres,
    types: GreenLight.Postgres.Types

  import Ecto.Query, warn: false
  alias Ecto.Multi

  def multi_update(multi, name, changeset) do
    multi
    |> multi_update_guard(name, changeset.data)
    |> Multi.update(name, changeset)
  end

  def multi_update_guard(multi, name, model) do
    Multi.run(multi, "#{name}_exists?", fn repo, _ ->
      if valid?(repo, model) do
        {:ok, true}
      else
        {:error, false}
      end
    end)
  end

  defp valid?(repo, %schema{id: id, updated_at: updated_at}) do
    from(e in schema, where: e.id == ^id and e.updated_at == ^updated_at)
    |> repo.exists?()
  end
end
