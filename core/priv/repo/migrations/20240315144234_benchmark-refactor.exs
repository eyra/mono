defmodule Core.Repo.Migrations.BenchmarkRefactor do
  use Ecto.Migration

  def up do
    alter table(:benchmark_tools) do
      remove(:status)
      remove(:title)
      remove(:expectations)
      remove(:data_set)
      remove(:template_repo)
      remove(:deadline)
      remove(:director)
      add(:max_submissions, :integer)
    end

    alter table(:benchmark_submissions) do
      remove(:spot_id)
      add(:tool_id, references(:benchmark_tools), null: false)
      add(:auth_node_id, references(:authorization_nodes), null: false)
    end

    drop(table(:benchmark_spots))

    alter table(:benchmark_leaderboards) do
      remove(:tool_id)
    end
  end

  def down do
    alter table(:benchmark_leaderboards) do
      # add(:tool_id, references(:benchmark_tools), null: false)
    end

    create table(:benchmark_spots) do
      add(:name, :string)
      add(:tool_id, references(:benchmark_tools), null: false)
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end

    alter table(:benchmark_submissions) do
      add(:spot_id, references(:benchmark_spots), null: false)
      remove(:tool_id)
      remove(:auth_node_id)
    end

    alter table(:benchmark_tools) do
      add(:status, :string, null: false)
      add(:title, :string, null: true)
      add(:expectations, :text, null: true)
      add(:data_set, :string, null: true)
      add(:deadline, :string)
      add(:director, :string, null: false)
      add(:template_repo, :string)
      remove(:max_submissions)
    end
  end
end
