defmodule Core.Repo.Migrations.RefactorPoolsPart5 do
  use Ecto.Migration

  import Ecto.Adapters.SQL

  def change do
    migrate_old_credit_transactions()
  end

  defp migrate_old_credit_transactions() do
    query_all(:book_entries, "id, idempotence_key", "idempotence_key LIKE 'assignment=%,user=%' AND idempotence_key NOT LIKE '%type=deposit%' AND idempotence_key NOT LIKE '%type=payment%'")
    |> Enum.each(&migrate_old_credit_transaction(&1))
  end

  defp migrate_old_credit_transaction([id, idempotence_key]) do
    update(:book_entries, id, :idempotence_key, "#{idempotence_key},type=payment")
  end
  defp migrate_old_credit_transaction(_), do: nil

  defp query_all(table, fields, where) do
    {:ok, %{rows: rows}} =
      query(Core.Repo, "SELECT #{fields} FROM #{table} WHERE #{where}")

    rows
  end

  defp update(table, id, field, value) when is_binary(value)do
    execute(
    """
    UPDATE #{table} SET #{field} = '#{value}' WHERE id = #{id};
    """
    )
  end

end
