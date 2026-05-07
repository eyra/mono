defmodule Core.Repo.Migrations.AddSubjectRewardToAssignmentInfo do
  use Ecto.Migration

  def change do
    alter table(:assignment_info) do
      add :subject_reward, :integer, default: 0, null: false
    end
  end
end
