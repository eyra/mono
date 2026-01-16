defmodule Core.Repo.Migrations.RenameStudentPool do
  use Ecto.Migration

  def up do
    rename_table(from: :books, to: :book_accounts)
    rename_fkey(from: :book_id, to: :account_id, table: :book_entry_lines)
    update(:pools, :name, "sbe_2021", "vu_students")
  end

  def down do
    rename_table(from: :book_accounts, to: :books)
    rename_fkey(from: :account_id, to: :book_id, table: :book_entry_lines)
    update(:pools, :name, "vu_students", "sbe_2021")
  end

  def update(table, field, new_value, old_value) do
    execute("""
    UPDATE #{table} SET #{field} = '#{new_value}' WHERE #{field} = '#{old_value}';
    """)
  end

  def rename_table(from: from_table_name, to: to_table_name) do
    execute("""
    ALTER TABLE #{from_table_name} RENAME TO #{to_table_name};
    """)
  end

  def rename_fkey(from: from_field, to: to_field, table: table_name) do
    from_fkey = build_identifier(table_name, from_field, :fkey)
    to_fkey = build_identifier(table_name, to_field, :fkey)

    rename_field(table_name, from_field, to_field)
    rename_constraint(table_name, from_fkey, to_fkey)
  end

  def rename_field(table, from, to) do
    execute("""
    ALTER TABLE #{table}
    RENAME COLUMN #{from} TO #{to};
    """)
  end

  def rename_constraint(table, from, to) do
    execute("""
    ALTER TABLE #{table} RENAME CONSTRAINT "#{from}" TO "#{to}";
    """)
  end

  @max_identifier_length 63
  def build_identifier(table_name, field_or_fields, ending) do
    ([table_name] ++ List.wrap(field_or_fields) ++ List.wrap(ending))
    |> Enum.join("_")
    |> String.slice(0, @max_identifier_length)
  end
end
