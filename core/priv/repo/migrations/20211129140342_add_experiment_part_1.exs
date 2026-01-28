defmodule Core.Repo.Migrations.AddExperimentPart1 do
  use Ecto.Migration

  def up do
    # Create Experiment
    create_experiment_table()
  end

  def down do
    # Drop Experiment
    drop_experiment_table()
  end

  defp create_experiment_table do
    create table(:experiments) do
      add(:subject_count, :integer)
      add(:duration, :string)
      add(:language, :string)
      add(:ethical_approval, :boolean)
      add(:ethical_code, :string)
      add(:devices, {:array, :string})

      add(:director, :string)

      add(:survey_tool_id, references(:survey_tools, on_delete: :delete_all), null: true)
      add(:lab_tool_id, references(:lab_tools, on_delete: :delete_all), null: true)

      add(:data_donation_tool_id, references(:data_donation_tools, on_delete: :delete_all),
        null: true
      )

      add(:auth_node_id, references(:authorization_nodes), null: false)

      timestamps()
    end

    flush()

    alter table(:assignments) do
      add(:assignable_experiment_id, references(:experiments, on_delete: :delete_all), null: true)
    end

    drop(constraint(:assignments, :must_have_at_least_one_assignable))
    flush()
  end

  defp drop_experiment_table do
    alter table(:assignments) do
      remove(:assignable_experiment_id)
    end

    create(
      constraint(:assignments, :must_have_at_least_one_assignable,
        check: """
          assignable_survey_tool_id != null or
          assignable_lab_tool_id != null or
          assignable_data_donation_tool_id != null
        """
      )
    )

    drop(table(:experiments))
  end
end
