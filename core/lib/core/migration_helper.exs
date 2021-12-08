defmodule Core.Repo.MigrationHelper  do

  defp link(table, id, field, value) do
    if not exist?(table, field, value) do
      update(table, id, field, value)
    end
  end

  defp update(table, id, field, value) when is_number(value)do
      execute(
      """
      UPDATE #{table} SET #{field} = #{value} WHERE id = #{id};
      """
      )
  end

  defp update(table, id, field, value) do
    execute(
    """
    UPDATE #{table} SET #{field} = '#{value}' WHERE id = #{id};
    """
    )
  end

  defp exist?(table, field, value) do
    exist?(table, "#{field} = #{value}")
  end

  defp exist?(table, where) do
    {:ok, %{ rows: [[count]] }} =
      query(Core.Repo, "SELECT count(*) FROM #{table} WHERE #{where};")

    count > 0
  end

  defp now() do
    DateTime.now!("Etc/UTC")
    |> DateTime.to_naive()
  end

  def rename_fkey(from: from_field, to: to_field, table: table_name) do
    from_fkey = build_identifier(table_name, from_field, :fkey)
    to_fkey = build_identifier(table_name, to_field, :fkey)

    rename_field(table_name, from_field, to_field)
    rename_constraint(table_name, from_fkey, to_fkey)
  end

  def rename_fkey(from: from_table_name, to: to_table_name, field: field) do
    from_fkey = build_identifier(from_table_name, field, :fkey)
    to_fkey = build_identifier(to_table_name, field, :fkey)

    rename_constraint(from_table_name, from_fkey, to_fkey)
  end

  def rename_pkey(from: from_table_name, to: to_table_name) do
    from_pkey = build_identifier(from_table_name, nil, :pkey)
    to_pkey = build_identifier(to_table_name, nil, :pkey)

    rename_constraint(from_table_name, from_pkey, to_pkey)
  end

  def rename_table(from: from_table_name, to: to_table_name) do
    execute(
      """
      ALTER TABLE #{from_table_name} RENAME TO #{to_table_name};
      """
    )
  end

  def rename_constraint(table, from, to) do
    execute(
      """
      ALTER TABLE #{table} RENAME CONSTRAINT "#{from}" TO "#{to}";
      """
    )
  end

  def rename_field(table, from, to) do
    execute(
      """
      ALTER TABLE #{table}
      RENAME COLUMN #{from} TO #{to};
      """
    )
  end

  @max_identifier_length 63
  def build_identifier(table_name, field_or_fields, ending) do
    ([table_name] ++ List.wrap(field_or_fields) ++ List.wrap(ending))
    |> Enum.join("_")
    |> String.slice(0, @max_identifier_length)
  end

end
