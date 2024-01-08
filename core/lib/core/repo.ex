defmodule Core.Repo do
  use Ecto.Repo,
    otp_app: :core,
    adapter: Ecto.Adapters.Postgres,
    types: GreenLight.Postgres.Types

  import Ecto.Query, warn: false
  alias Ecto.Multi

  require Logger

  def multi_update(multi, name, changeset) do
    multi
    |> multi_update_guard(name, changeset.data)
    |> Multi.update(name, changeset)
  end

  def multi_update_guard(multi, name, model) do
    Multi.run(multi, "#{name}_up_to_date?", fn repo, _ ->
      if up_to_date?(repo, model) do
        {:ok, true}
      else
        message = "#{String.capitalize(name)} is not up to date, preventing database change"
        Logger.warning(message)
        {:error, message}
      end
    end)
  end

  defp up_to_date?(repo, %schema{id: id, updated_at: updated_at}) do
    from(e in schema, where: e.id == ^id and e.updated_at == ^updated_at)
    |> repo.exists?()
  end
end
