defmodule Core.Repo.Migrations.AddExperimentPart3 do
  use Ecto.Migration

  def up do
    create constraint(:assignments, :must_have_at_least_one_assignable, check:
      """
      assignable_experiment_id != null
      """
    )

    create constraint(:experiments, :must_have_at_least_one_tool, check:
      """
      survey_tool_id != null or
      lab_tool_id != null or
      data_donation_tool_id != null
      """
    )
  end

  def down do
    drop constraint(:experiments, :must_have_at_least_one_tool)
    drop constraint(:assignments, :must_have_at_least_one_assignable)
  end
end
