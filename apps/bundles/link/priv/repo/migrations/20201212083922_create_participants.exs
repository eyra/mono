defmodule Link.Repo.Migrations.CreateParticipants do
  use Ecto.Migration

  def change do
    create table(:study_participants, primary_key: false) do
      add(:user_id, references(:users, on_delete: :nothing))
      add(:study_id, references(:studies, on_delete: :nothing))

      timestamps()
    end

    # Used to ensure there is only one study application for each user. Also
    # allows quick listing of studies belonging to a user.
    create(unique_index(:study_participants, [:user_id, :study_id]))
    # Enables fast lookup of participants in a given study.
    create(index(:study_participants, [:study_id]))
  end
end
