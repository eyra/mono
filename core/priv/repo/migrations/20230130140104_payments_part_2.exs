defmodule Core.Repo.Migrations.PaymentsPart2 do
  use Ecto.Migration

  import Ecto.Adapters.SQL

  def up do
    migrate_scholar_nodes({"scholar", "student"})
    migrate_pools()
  end

  def down do
    migrate_scholar_nodes({"student", "scholar"})
  end

  defp migrate_pools() do
    query_all(:pools, "id")
    |> Enum.each(&migrate_pool(&1))
  end

  defp migrate_pool([id]) do
    update(:pools, id, :director, "student")
    auth_node_id = create_auth_node(:pools, id)

    query_all(:users, "id", "coordinator = true")
    |> Enum.each(&add_owner(&1, auth_node_id))
  end

  defp create_auth_node(table, id) do
    execute("""
    INSERT INTO authorization_nodes (inserted_at, updated_at)
    VALUES ('#{now()}', '#{now()}');
    """)

    execute("""
    UPDATE #{table} SET auth_node_id = CURRVAL('authorization_nodes_id_seq') WHERE id = '#{id}' ;
    """)

    flush()

    query_field(table, :auth_node_id, "id = #{id}")
  end

  defp add_owner([user_id], auth_node_id) do
    execute("""
    INSERT INTO authorization_role_assignments (node_id, principal_id, role, inserted_at, updated_at)
    VALUES (#{auth_node_id}, #{user_id}, 'owner', '#{now()}', '#{now()}');
    """)

    flush()
  end

  defp migrate_scholar_nodes(rule) do
    query_all(:org_nodes, "id, type")
    |> Enum.each(&migrate_scholar_node(&1, rule))
  end

  defp migrate_scholar_node([id, type], {from, to}) do
    new_type = String.replace(type, from, to)
    update(:org_nodes, id, :type, new_type)
  end

  defp query_all(table, fields) do
    {:ok, %{rows: rows}} = query(Core.Repo, "SELECT #{fields} FROM #{table}")

    rows
  end

  def query_field(table, field, where) do
    {:ok, %{rows: [[value] | _]}} =
      query(Core.Repo, "SELECT #{field} FROM #{table} WHERE #{where}")

    value
  end

  defp query_all(table, fields, where) do
    {:ok, %{rows: rows}} = query(Core.Repo, "SELECT #{fields} FROM #{table} WHERE #{where}")

    rows
  end

  defp update(table, id, field, value) when is_binary(value) do
    execute("""
    UPDATE #{table} SET #{field} = '#{value}' WHERE id = #{id};
    """)
  end

  defp now() do
    DateTime.now!("Etc/UTC")
    |> DateTime.to_naive()
  end
end
