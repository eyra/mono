defmodule Core.Repo.Migrations.AddStateToStudyParticipants do
  use Ecto.Migration

  def change do
    alter table(:study_participants) do
      add(:status, :string)
    end

    create(index(:study_participants, [:status]))
    execute("update study_participants set status='applied'")

    alter table(:study_participants) do
      modify(:status, :string, null: false)
    end
  end
end
