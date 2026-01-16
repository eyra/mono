defmodule Core.Repo.Migrations.MigrateSurveyTool do
  use Ecto.Migration

  import Ecto.Adapters.SQL

  def up do
    [:survey_tool, :lab_tool, :data_donation_tool]
    |> Enum.each(&migrate(&1))
  end

  def down do
  end

  defp migrate(tool_type) do
    query(Core.Repo, "SELECT id FROM #{tool_type}s WHERE director = 'assignment';")
    |> migrate_tools(tool_type)
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

  defp migrate_tool([id], tool_type) do
    set_director(id, "#{tool_type}s", :campaign)
  end

  defp set_director(id, table, director) do
    update(table, id, :director, director)
  end

  defp update(table, id, field, value) do
    execute("""
    UPDATE #{table} SET #{field} = '#{value}' WHERE id = #{id};
    """)
  end
end
