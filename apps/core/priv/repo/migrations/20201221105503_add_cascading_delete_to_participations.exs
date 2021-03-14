defmodule Core.Repo.Migrations.AddCascadingDeleteToParticipations do
  use Ecto.Migration

  def up do
    drop(constraint(:study_participants, "study_participants_user_id_fkey"))
    drop(constraint(:study_participants, "study_participants_study_id_fkey"))

    alter table(:study_participants) do
      modify(:user_id, references(:users, on_delete: :delete_all))
    end
  end

  def down do
    drop(constraint(:study_participants, "study_participants_user_id_fkey"))
    drop(constraint(:study_participants, "study_participants_study_id_fkey"))

    alter table(:study_participants) do
      modify(:user_id, references(:users, on_delete: :nothing))
    end
  end
end
