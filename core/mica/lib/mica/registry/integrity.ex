defmodule Mica.Registry.Integrity do
  @moduledoc """
  Counts the tool refs and project items whose reference doesn't hold. Without one
  foreign key per type (code-registry), this check is what finds them. It only
  reports: it never removes anything, so a future archive feature can keep
  references to archived targets (d-0030).

  Per registered type it counts the rows whose target row is missing. Across all
  types it counts the rows whose type the composition doesn't have, and the rows of
  the reserved type `none` (expected: references kept from before 2023). Tool refs
  that no workflow item holds are counted too; deleting a workflow item leaves them.
  """

  alias Mica.Repo

  @doc "The counts, per table."
  def check do
    %{
      tool_refs: %{
        missing_target: missing_targets("tool_refs", "tool_type", "tool_id", Mica.Tools.all()),
        unknown_type: unknown_types("tool_refs", "tool_type", Mica.Tools.all()),
        none: count("SELECT count(*) FROM tool_refs WHERE tool_type = 'none'"),
        without_workflow_item:
          count("""
          SELECT count(*) FROM tool_refs r
          WHERE NOT EXISTS (SELECT 1 FROM workflow_items i WHERE i.tool_ref_id = r.id)
          """)
      },
      project_items: %{
        missing_target:
          missing_targets("project_items", "item_type", "item_id", Mica.ProjectItems.all()),
        unknown_type: unknown_types("project_items", "item_type", Mica.ProjectItems.all()),
        none: count("SELECT count(*) FROM project_items WHERE item_type = 'none'")
      }
    }
  end

  @doc "True when a reference doesn't hold: a missing target or an unknown type."
  def problems?(%{} = counts) do
    Enum.any?(counts, fn {_table, %{missing_target: missing, unknown_type: unknown}} ->
      unknown > 0 or Enum.any?(missing, fn {_type, n} -> n > 0 end)
    end)
  end

  # The table of each type comes from its schema, which a system registers.
  defp missing_targets(table, type_column, id_column, modules) do
    Map.new(modules, fn module ->
      target = module.schema().__schema__(:source)

      {module.type(),
       count(
         """
         SELECT count(*) FROM #{table} r
         WHERE r.#{type_column} = $1
           AND NOT EXISTS (SELECT 1 FROM #{target} t WHERE t.id = r.#{id_column})
         """,
         [module.type()]
       )}
    end)
  end

  defp unknown_types(table, type_column, modules) do
    known = ["none" | Enum.map(modules, & &1.type())]

    count(
      "SELECT count(*) FROM #{table} WHERE #{type_column} IS NULL OR #{type_column} <> ALL($1)",
      [known]
    )
  end

  defp count(sql, params \\ []) do
    %{rows: [[n]]} = Repo.query!(sql, params)
    n
  end
end
