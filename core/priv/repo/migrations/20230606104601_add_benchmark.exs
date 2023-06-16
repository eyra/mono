defmodule Core.Repo.Migrations.AddBenchmark do
  use Ecto.Migration

  def up do
    create table(:benchmark_tools) do
      add(:status, :string, null: false)
      add(:title, :string, null: true)
      add(:expectations, :text, null: true)
      add(:data_set, :string, null: true)
      add(:deadline, :string)
      add(:director, :string, null: false)
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end

    create table(:benchmark_spots) do
      add(:name, :string)
      add(:tool_id, references(:benchmark_tools), null: false)
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end

    create(unique_index(:benchmark_spots, [:tool_id, :name]))

    create table(:benchmark_leaderboards) do
      add(:name, :string)
      add(:version, :string)
      add(:tool_id, references(:benchmark_tools), null: false)
      timestamps()
    end

    create(unique_index(:benchmark_leaderboards, [:name, :version]))

    create table(:benchmark_submissions) do
      add(:spot_id, references(:benchmark_spots), null: false)
      add(:description, :string, null: false)
      add(:github_commit_url, :string, null: false)
      timestamps()
    end

    create table(:benchmark_scores) do
      add(:score, :float, null: false)
      add(:leaderboard_id, references(:benchmark_leaderboards), null: false)
      add(:submission_id, references(:benchmark_submissions), null: false)
      timestamps()
    end

    create(
      unique_index(:benchmark_scores, [:leaderboard_id, :submission_id],
        name: :benchmark_scores_leaderboard_id_submission_id_index
      )
    )

    alter table(:tool_refs) do
      add(:benchmark_tool_id, references(:benchmark_tools, on_delete: :delete_all), null: true)
    end

    drop(constraint(:tool_refs, :must_have_at_least_one_tool))

    create(
      constraint(:tool_refs, :must_have_at_least_one_tool,
        check: """
        survey_tool_id != null or
        lab_tool_id != null or
        data_donation_tool_id != null or
        benchmark_tool_id != null
        """
      )
    )
  end

  def down do
    drop(constraint(:tool_refs, :must_have_at_least_one_tool))

    create(
      constraint(:tool_refs, :must_have_at_least_one_tool,
        check: """
        survey_tool_id != null or
        lab_tool_id != null or
        data_donation_tool_id != null
        """
      )
    )

    alter table(:tool_refs) do
      remove(:benchmark_tool_id)
    end

    drop(index(:benchmark_scores, [:leaderboard_id, :submission_id]))
    drop(index(:benchmark_leaderboards, [:name, :version]))
    drop(index(:benchmark_spots, [:tool_id, :name]))

    drop(table(:benchmark_scores))
    drop(table(:benchmark_submissions))
    drop(table(:benchmark_leaderboards))
    drop(table(:benchmark_spots))
    drop(table(:benchmark_tools))
  end
end
