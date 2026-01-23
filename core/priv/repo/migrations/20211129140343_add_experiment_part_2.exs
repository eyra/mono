defmodule Core.Repo.Migrations.AddExperimentPart2 do
  use Ecto.Migration

  import Ecto.Adapters.SQL

  def up do
    migrate_tools(:survey_tool)
  end

  def down do
  end

  defp migrate_tools(tool_type) do
    tools =
      query(Core.Repo, "SELECT assignable_#{tool_type}_id, id, auth_node_id FROM assignments;")

    migrate_tools(tools, tool_type)
  end

  defp migrate_tools({:ok, %{rows: []}}, tool_type) do
    IO.puts("No #{tool_type}s found to migrate")
  end

  defp migrate_tools({:ok, %{rows: tools}}, tool_type) do
    migrate_tools(tools, tool_type)
  end

  defp migrate_tools([], _), do: :noop

  defp migrate_tools([h | t], tool_type) do
    migrate_tool(h, tool_type)
    migrate_tools(t, tool_type)
  end

  defp migrate_tool([tool_id, nil, _], tool_type) do
    IO.puts("No assignment found for #{tool_type} #{tool_id}")
  end

  defp migrate_tool([id, assignment_id, assignment_auth_node_id], tool_type) do
    {:ok, %{rows: tools}} =
      query(
        Core.Repo,
        "SELECT id, subject_count, duration, language, ethical_approval, ethical_code, devices FROM #{tool_type}s WHERE id = #{id};"
      )

    tool = tools |> List.first()

    with [tool_id, subject_count, duration, language, ethical_approval, ethical_code, devices] =
           tool do
      experiment_id =
        create_experiment(assignment_auth_node_id, tool_type, %{
          id: tool_id,
          subject_count: nillable(subject_count),
          duration: nillable(duration),
          language: nillable(language),
          ethical_approval: nillable(ethical_approval),
          ethical_code: nillable(ethical_code),
          devices: to_string_array(devices)
        })

      link(:assignments, assignment_id, :assignable_experiment_id, experiment_id)
    end
  end

  defp create_experiment(assignment_auth_node_id, tool_type, %{
         id: tool_id,
         subject_count: subject_count,
         duration: duration,
         language: language,
         ethical_approval: ethical_approval,
         ethical_code: ethical_code,
         devices: devices
       }) do
    if not exist?(:experiments, "#{tool_type}_id", tool_id) do
      execute("""
      INSERT INTO authorization_nodes (parent_id, inserted_at, updated_at)
      VALUES (#{assignment_auth_node_id}, '#{now()}', '#{now()}');
      """)

      execute("""
      INSERT INTO experiments (#{tool_type}_id, director, subject_count, duration, language, ethical_approval, ethical_code, devices, auth_node_id, inserted_at, updated_at)
      VALUES (#{tool_id}, 'assignment', #{subject_count}, #{duration}, '#{language}', #{ethical_approval}, '#{ethical_code}', '#{devices}', CURRVAL('authorization_nodes_id_seq'), '#{now()}', '#{now()}');
      """)

      flush()
    end

    query_id(:experiments, "#{tool_type}_id = #{tool_id}")
  end

  # Migration Helpers

  def to_string_array(nil), do: "{}"

  def to_string_array(enum) do
    "{" <> Enum.join(enum, ",") <> "}"
  end

  def nillable(nil), do: "null"
  def nillable(term), do: term

  def link(table, id, field, value) do
    if not exist?(table, field, value) do
      update(table, id, field, value)
    end
  end

  def update(table, id, field, value) when is_number(value) do
    execute("""
    UPDATE #{table} SET #{field} = #{value} WHERE id = #{id};
    """)
  end

  def update(table, id, field, value) do
    execute("""
    UPDATE #{table} SET #{field} = '#{value}' WHERE id = #{id};
    """)
  end

  def exist?(table, field, value) do
    exist?(table, "#{field} = #{value}")
  end

  def exist?(table, where) do
    {:ok, %{rows: [[count]]}} =
      query(Core.Repo, "SELECT count(*) FROM #{table} WHERE #{where};")

    count > 0
  end

  def query_id(table, where) do
    query_field(table, :id, where)
  end

  def query_field(table, field, where) do
    {:ok, %{rows: [[id] | _]}} =
      query(Core.Repo, "SELECT #{field} FROM #{table} WHERE #{where}")

    id
  end

  def now() do
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
    execute("""
    ALTER TABLE #{from_table_name} RENAME TO #{to_table_name};
    """)
  end

  def rename_constraint(table, from, to) do
    execute("""
    ALTER TABLE #{table} RENAME CONSTRAINT "#{from}" TO "#{to}";
    """)
  end

  def rename_field(table, from, to) do
    execute("""
    ALTER TABLE #{table}
    RENAME COLUMN #{from} TO #{to};
    """)
  end

  @max_identifier_length 63
  def build_identifier(table_name, field_or_fields, ending) do
    ([table_name] ++ List.wrap(field_or_fields) ++ List.wrap(ending))
    |> Enum.join("_")
    |> String.slice(0, @max_identifier_length)
  end
end
