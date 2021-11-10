defmodule Core.Repo.Migrations.RefactorCampaignPromotionAssignment do
  use Ecto.Migration

  import Ecto.Query, warn: false

  def up do
    #Rename Studies -> Campaigns
    rename_pkey(from: :studies, to: :campaigns)
    rename_fkey(from: :studies, to: :campaigns, field: :auth_node_id)
    rename_fkey(from: :study_id, to: :campaign_id, table: :authors)
    rename_fkey(from: :study_id, to: :campaign_id, table: :client_scripts)
    rename_fkey(from: :study_id, to: :campaign_id, table: :data_donation_tools)
    rename_fkey(from: :study_id, to: :campaign_id, table: :lab_tools)
    rename_fkey(from: :study_id, to: :campaign_id, table: :survey_tools)
    rename_table(from: :studies, to: :campaigns)

    #Create Assignment
    create_assignment_table()

    # Add director field
    add_directors()
  end

  def down do
    # Drop director field
    drop_directors()

    #Drop Assignment
    drop_assignment_table()

    #Rename Campaigns -> Studies
    rename_pkey(from: :campaigns, to: :studies)
    rename_fkey(from: :campaigns, to: :studies, field: :auth_node_id)
    rename_fkey(from: :campaign_id, to: :study_id, table: :authors)
    rename_fkey(from: :campaign_id, to: :study_id, table: :client_scripts)
    rename_fkey(from: :campaign_id, to: :study_id, table: :data_donation_tools)
    rename_fkey(from: :campaign_id, to: :study_id, table: :lab_tools)
    rename_fkey(from: :campaign_id, to: :study_id, table: :survey_tools)
    rename_table(from: :campaigns, to: :studies)
  end

  defp add_directors do
    [
      :promotions,
      :survey_tools,
      :lab_tools,
      :data_donation_tools,
      :pool_submissions
    ]
    |> Enum.each(&add_director(&1))
  end

  defp drop_directors do
    [
      :promotions,
      :survey_tools,
      :lab_tools,
      :data_donation_tools,
      :pool_submissions
    ]
    |> Enum.each(&drop_director(&1))
  end

  defp add_director(table) do
    alter table(table) do
      add(:director, :string)
    end
  end

  defp drop_director(table) do
    alter table(table) do
      remove(:director)
    end
  end

  defp create_assignment_table do
    create table(:assignments) do
      add(:director, :string)
      add(:assignable_survey_tool_id, references(:survey_tools, on_delete: :delete_all), null: true)
      add(:assignable_lab_tool_id, references(:lab_tools, on_delete: :delete_all), null: true)
      add(:assignable_data_donation_tool_id, references(:data_donation_tools, on_delete: :delete_all), null: true)
      add(:crew_id, references(:crews, on_delete: :delete_all), null: true)
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end
    create constraint(:assignments, :must_have_at_least_one_assignable, check:
      """
      assignable_survey_tool_id != null or
      assignable_lab_tool_id != null or
      assignable_data_donation_tool_id != null
      """
    )
    flush()
    alter table(:campaigns) do
      add(:promotion_id, references(:promotions, on_delete: :delete_all), null: true)
      add(:promotable_assignment_id, references(:assignments, on_delete: :delete_all), null: true)
    end
    create constraint(:campaigns, :must_have_at_least_one_promotable, check:
      """
      promotable_assignment_id != null
      """
    )

    alter table(:promotions) do
      modify(:plugin, :string, null: true)
    end

    flush()
  end

  defp drop_assignment_table do
    alter table(:promotions) do
      modify(:plugin, :string, null: false)
    end

    drop constraint(:campaigns, :must_have_at_least_one_promotable)
    alter table(:campaigns) do
      remove(:promotion_id)
      remove(:promotable_assignment_id)
    end
    drop constraint(:assignments, :must_have_at_least_one_assignable)
    drop table(:assignments)
  end

  defp rename_fkey(from: from_field, to: to_field, table: table_name) do
    from_fkey = build_identifier(table_name, from_field, :fkey)
    to_fkey = build_identifier(table_name, to_field, :fkey)

    rename_field(table_name, from_field, to_field)
    rename_constraint(table_name, from_fkey, to_fkey)
  end

  defp rename_fkey(from: from_table_name, to: to_table_name, field: field) do
    from_fkey = build_identifier(from_table_name, field, :fkey)
    to_fkey = build_identifier(to_table_name, field, :fkey)

    rename_constraint(from_table_name, from_fkey, to_fkey)
  end

  defp rename_pkey(from: from_table_name, to: to_table_name) do
    from_pkey = build_identifier(from_table_name, nil, :pkey)
    to_pkey = build_identifier(to_table_name, nil, :pkey)

    rename_constraint(from_table_name, from_pkey, to_pkey)
  end

  defp rename_table(from: from_table_name, to: to_table_name) do
    execute(
      """
      ALTER TABLE #{from_table_name} RENAME TO #{to_table_name};
      """
    )
  end

  defp rename_constraint(table, from, to) do
    execute(
      """
      ALTER TABLE #{table} RENAME CONSTRAINT "#{from}" TO "#{to}";
      """
    )
  end

  defp rename_field(table, from, to) do
    execute(
      """
      ALTER TABLE #{table}
      RENAME COLUMN #{from} TO #{to};
      """
    )
  end

  @max_identifier_length 63
  defp build_identifier(table_name, field_or_fields, ending) do
    ([table_name] ++ List.wrap(field_or_fields) ++ List.wrap(ending))
    |> Enum.join("_")
    |> String.slice(0, @max_identifier_length)
  end

end
