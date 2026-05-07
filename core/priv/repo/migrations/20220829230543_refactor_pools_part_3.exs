defmodule Core.Repo.Migrations.RefactorPoolsPart3 do
  use Ecto.Migration

  import Ecto.Adapters.SQL

  def up do
    migrate_funds()
    migrate_assignments()
  end

  defp migrate_assignments() do
    query_all(:campaigns, "id, promotion_id, promotable_assignment_id")
    |> Enum.each(&migrate_assignment(&1))
  end

  defp migrate_assignment([_id, promotion_id, assignment_id]) do
    if exist?(:pool_submissions, :promotion_id, promotion_id) do
      submission_id = query_id(:pool_submissions, "promotion_id = #{promotion_id}")

      study_program_codes =
        query_field(
          :eligibility_criteria,
          "study_program_codes",
          "submission_id = #{submission_id}"
        )

      budget_name =
        study_program_codes
        |> get_year()
        |> get_budget_name()

      budget_id = query_id(:budgets, "name = '#{budget_name}'")
      update(:assignments, assignment_id, :budget_id, budget_id)
    end
  end

  defp migrate_funds() do
    template = ["fund"] |> array_to_db_string()

    query_all(:book_accounts, "id, identifier", "identifier @> '#{template}' ")
    |> Enum.each(&migrate_fund(&1))
  end

  defp migrate_fund([fund_id, [_, currency_name]]) do
    currency_id = query_id(:currencies, "name = '#{currency_name}'")
    reserve_id = add_reserve(currency_name)
    add_budget(currency_name, currency_id, fund_id, reserve_id)
  end

  defp add_reserve(name) do
    identifier = ["reserve", name] |> array_to_db_string()

    if not exist?(:book_accounts, :identifier, identifier) do
      execute("""
      INSERT INTO book_accounts (identifier, balance_debit, balance_credit, inserted_at, updated_at)
      VALUES ('#{identifier}', 0, 0, '#{now()}', '#{now()}');
      """)

      flush()
    end

    query_id(:book_accounts, "identifier = '#{identifier}'")
  end

  defp add_budget(name, currency_id, fund_id, reserve_id) do
    if not exist?(:budgets, :name, name) do
      execute("""
      INSERT INTO authorization_nodes (inserted_at, updated_at)
      VALUES ('#{now()}', '#{now()}');
      """)

      execute("""
      INSERT INTO budgets (name, currency_id, fund_id, reserve_id, auth_node_id, inserted_at, updated_at)
      VALUES ('#{name}', #{currency_id}, #{fund_id}, #{reserve_id}, CURRVAL('authorization_nodes_id_seq'), '#{now()}', '#{now()}');
      """)

      flush()
    end

    query_id(:budgets, "name = '#{name}'")
  end

  def down do
  end

  ########## HELPERS ##########

  defp get_year([code | _]) do
    if code |> String.contains?("1") do
      :first
    else
      :second
    end
  end

  defp get_budget_name(:first), do: "vu_sbe_rpr_year1_2021"
  defp get_budget_name(:second), do: "vu_sbe_rpr_year2_2021"

  def exist?(table, field, value) when is_atom(value) do
    exist?(table, "#{field} = '#{value}'")
  end

  def exist?(table, field, value) when is_binary(value) do
    exist?(table, "#{field} = '#{value}'")
  end

  def exist?(table, field, value) do
    exist?(table, "#{field} = #{value}")
  end

  def exist?(table, where) do
    {:ok, %{rows: [[count]]}} =
      query(Core.Repo, "SELECT count(*) FROM #{table} WHERE #{where};")

    count > 0
  end

  defp query_id(table, where) do
    query_field(table, :id, where)
  end

  defp query_field(table, field, where) do
    {:ok, %{rows: [[id] | _]}} =
      query(Core.Repo, "SELECT #{field} FROM #{table} WHERE #{where}")

    id
  end

  defp query_all(table, fields, where) do
    {:ok, %{rows: rows}} =
      query(Core.Repo, "SELECT #{fields} FROM #{table} WHERE #{where}")

    rows
  end

  defp query_all(table, fields) do
    {:ok, %{rows: rows}} =
      query(Core.Repo, "SELECT #{fields} FROM #{table}")

    rows
  end

  defp update(table, id, field, value) when is_number(value) do
    execute("""
    UPDATE #{table} SET #{field} = #{value} WHERE id = #{id};
    """)
  end

  defp array_to_db_string(array) do
    result =
      array
      |> Enum.join(",")

    "{#{result}}"
  end

  def now() do
    DateTime.now!("Etc/UTC")
    |> DateTime.to_naive()
  end
end
