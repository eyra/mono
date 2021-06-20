defmodule Core.Repo.Migrations.PortDemo do
  use Ecto.Migration

  def change do

    # CONTENT_NODE
    create table(:content_nodes) do
      add(:ready, :boolean)
      add(:parent_id, references(:content_nodes, on_delete: :delete_all), null: true)

      timestamps()
    end

    # PROMOTION
    create table(:promotions) do
      add(:title, :string)
      add(:subtitle, :string)
      add(:expectations, :text)
      add(:description, :text)
      add(:published_at, :naive_datetime)
      add(:image_id, :text)
      add(:themes, {:array, :string})
      add(:marks, {:array, :string})
      add(:banner_photo_url, :string)
      add(:banner_title, :string)
      add(:banner_subtitle, :string)
      add(:banner_url, :string)

      add(:plugin, :string)

      add(:auth_node_id, references(:authorization_nodes), null: false)
      add(:content_node_id, references(:content_nodes), null: false)

      timestamps()
    end

    # TOOLS
    create table(:data_donation_tools) do
      add(:script, :text)
      add(:reward_currency, :string)
      add(:reward_value, :integer)
      add(:subject_count, :integer)

      add(:promotion_id, references(:promotions))
      add(:study_id, references(:studies, on_delete: :delete_all))
      add(:auth_node_id, references(:authorization_nodes), null: false)

      add(:content_node_id, references(:content_nodes), null: false)

      timestamps()
    end

    create(index(:data_donation_tools, [:study_id]))
    create(index(:data_donation_tools, [:promotion_id]))

    # TASKS
    create table(:data_donation_tasks) do
      add(:status, :string, null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:data_donation_tool_id, references(:data_donation_tools, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:data_donation_tasks, [:status]))
    create(index(:data_donation_tasks, [:data_donation_tool_id]))
    create(unique_index(:data_donation_tasks, [:user_id, :data_donation_tool_id]))

    # PARTICIPANTS
    create table(:data_donation_participants) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:data_donation_tool_id, references(:data_donation_tools, on_delete: :delete_all))

      timestamps()
    end

    create(unique_index(:data_donation_participants, [:data_donation_tool_id, :user_id]))


  end
end
