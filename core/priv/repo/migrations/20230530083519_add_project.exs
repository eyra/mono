defmodule Core.Repo.Migrations.AddProject do
  use Ecto.Migration

  def up do
    alter table(:data_donation_tools) do
      add(:platforms, {:array, :string}, null: true)
      remove(:script)
      remove(:reward_currency, :string)
      remove(:reward_value, :integer)

      remove(:promotion_id)
      remove(:campaign_id)
      remove(:content_node_id)
    end

    create table(:project_nodes) do
      add(:name, :string, null: false)
      add(:project_path, {:array, :integer}, null: false)
      add(:parent_id, references(:project_nodes), null: true)
      add(:auth_node_id, references(:authorization_nodes), null: true)
      timestamps()
    end

    create table(:projects) do
      add(:name, :string, null: false)
      add(:auth_node_id, references(:authorization_nodes), null: true)
      add(:root_id, references(:project_nodes))
      timestamps()
    end

    create table(:tool_refs) do
      add(:lab_tool_id, references(:lab_tools, on_delete: :delete_all), null: true)
      add(:survey_tool_id, references(:survey_tools, on_delete: :delete_all), null: true)

      add(:data_donation_tool_id, references(:data_donation_tools, on_delete: :delete_all),
        null: true
      )

      timestamps()
    end

    create table(:project_items) do
      add(:name, :string, null: false)
      add(:project_path, {:array, :integer}, null: false)
      add(:node_id, references(:project_nodes, on_delete: :delete_all), null: false)
      add(:tool_ref_id, references(:tool_refs, on_delete: :delete_all), null: false)
      timestamps()
    end

    drop(index(:data_donation_tasks, [:status]))
    drop(index(:data_donation_tasks, [:tool_id]))
    drop(index(:data_donation_tasks, [:user_id, :tool_id]))

    alter table(:data_donation_tasks) do
      remove(:status)
      remove(:user_id)
      remove(:tool_id)

      add(:position, :integer)
      add(:title, :string)
      add(:description, :string)
    end

    create(
      constraint(:tool_refs, :must_have_at_least_one_tool,
        check: """
        survey_tool_id != null or
        lab_tool_id != null or
        data_donation_tool_id != null
        """
      )
    )
  end

  def down do
    alter table(:data_donation_tasks) do
      remove(:position)
      remove(:title)
      remove(:description)

      add(:status, :string, null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:tool_id, references(:data_donation_tools, on_delete: :delete_all), null: false)
    end

    create(index(:data_donation_tasks, [:status]))
    create(index(:data_donation_tasks, [:tool_id]))
    create(unique_index(:data_donation_tasks, [:user_id, :tool_id]))

    drop(constraint(:tool_refs, :must_have_at_least_one_tool))
    drop(table(:project_items))
    drop(table(:tool_refs))
    drop(table(:projects))
    drop(table(:project_nodes))

    alter table(:data_donation_tools) do
      remove(:platforms)
      add(:script, :text)
      add(:reward_currency, :string)
      add(:reward_value, :integer)
      add(:promotion_id, references(:promotions))
      add(:campaign_id, references(:campaigns, on_delete: :delete_all))
      add(:content_node_id, references(:content_nodes), null: true)
    end
  end
end
