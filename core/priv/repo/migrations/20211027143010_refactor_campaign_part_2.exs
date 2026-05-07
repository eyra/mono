defmodule Core.Repo.Migrations.RefactorCampaignPart2 do
  use Ecto.Migration

  import Ecto.Adapters.SQL

  def up do
    migrate_tools(:survey_tool)
    migrate_tools(:lab_tool)
    migrate_tools(:data_donation_tool)
  end

  def down do
  end

  defp migrate_tools(tool_type) do
    tools = query(Core.Repo, "SELECT id,campaign_id FROM #{tool_type}s;")
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

  defp migrate_tool([tool_id, nil], tool_type) do
    IO.puts("No campaign found for #{tool_type} #{tool_id}")
  end

  defp migrate_tool([id, campaign_id], tool_type) do
    assignment_id = create_assignment(id, campaign_id, tool_type)

    assignment_id
    |> link_campaign_assignment(campaign_id)
    |> create_crew(campaign_id)
    |> link_assignment_crew(assignment_id)

    promotion_id =
      get_promotion(tool_type, id)
      |> link_campaign_promotion(campaign_id)
      |> set_director(:promotions, :campaign)

    get_pool_submission(promotion_id)
    |> set_director(:pool_submissions, :campaign)
  end

  defp get_promotion(tool_type, tool_id) do
    query_field("#{tool_type}s", :promotion_id, "id = #{tool_id}")
  end

  defp get_pool_submission(promotion_id) do
    query_id(:pool_submissions, "promotion_id = #{promotion_id}")
  end

  defp create_assignment(tool_id, campaign_id, tool_type) do
    if not exist?(:assignments, "assignable_#{tool_type}_id", tool_id) do
      execute("""
      INSERT INTO assignments (assignable_#{tool_type}_id, director, auth_node_id, inserted_at, updated_at)
      VALUES (#{tool_id}, 'campaign', CURRVAL('authorization_nodes_id_seq'), '#{now()}', '#{now()}');
      """)

      execute("""
      INSERT INTO authorization_nodes (parent_id, inserted_at, updated_at)
      VALUES (#{campaign_id}, '#{now()}', '#{now()}');
      """)

      flush()
    end

    set_director(tool_id, "#{tool_type}s", "assignment")

    query_id(:assignments, "assignable_#{tool_type}_id = #{tool_id}")
  end

  defp create_crew(assignment_id, campaign_id) do
    if not exist?(:crews, "reference_type = 'campaign' AND reference_id = #{campaign_id}") do
      execute("""
      INSERT INTO authorization_nodes (parent_id, inserted_at, updated_at)
      VALUES (#{assignment_id}, '#{now()}', '#{now()}');
      """)

      execute("""
      INSERT INTO crews (reference_type, reference_id, auth_node_id, inserted_at, updated_at)
      VALUES ('campaign', #{campaign_id}, CURRVAL('authorization_nodes_id_seq'), '#{now()}', '#{now()}');
      """)

      flush()
    end

    query_id(:crews, "reference_type = 'campaign' AND reference_id = #{campaign_id}")
  end

  defp set_director(id, table, director) do
    update(table, id, :director, director)
    id
  end

  defp link_assignment_crew(crew_id, assignment_id) do
    link(:assignments, assignment_id, :crew_id, crew_id)
    crew_id
  end

  defp link_campaign_promotion(nil, _) do
    IO.puts("No promotion found")
  end

  defp link_campaign_promotion(promotion_id, campaign_id) do
    link(:campaigns, campaign_id, :promotion_id, promotion_id)
    promotion_id
  end

  defp link_campaign_assignment(assignment_id, campaign_id) do
    link(:campaigns, campaign_id, :promotable_assignment_id, assignment_id)
    assignment_id
  end

  defp link(table, id, field, value) do
    if not exist?(table, field, value) do
      update(table, id, field, value)
    end
  end

  defp update(table, id, field, value) when is_number(value) do
    execute("""
    UPDATE #{table} SET #{field} = #{value} WHERE id = #{id};
    """)
  end

  defp update(table, id, field, value) do
    execute("""
    UPDATE #{table} SET #{field} = '#{value}' WHERE id = #{id};
    """)
  end

  defp exist?(table, field, value) do
    exist?(table, "#{field} = #{value}")
  end

  defp exist?(table, where) do
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

  defp now() do
    DateTime.now!("Etc/UTC")
    |> DateTime.to_naive()
  end
end
