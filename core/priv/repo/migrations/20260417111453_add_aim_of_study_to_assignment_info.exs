defmodule Core.Repo.Migrations.AddAimOfStudyToAssignmentInfo do
  use Ecto.Migration

  def change do
    alter table(:assignment_info) do
      add :aim_of_study, :string, size: 250
    end
  end
end
