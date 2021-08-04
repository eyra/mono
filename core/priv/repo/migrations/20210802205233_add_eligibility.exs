defmodule Core.Repo.Migrations.AddEligibility do
  use Ecto.Migration

  def change do
    create table(:user_features) do
      add(:gender, :string)
      add(:dominant_hand, :string)
      add(:native_language, :string)
      add(:study_program_codes, {:array, :string})

      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(unique_index(:user_features, [:user_id]))

    create table(:eligibility_criteria) do
      add(:genders, {:array, :string})
      add(:dominant_hands, {:array, :string})
      add(:native_languages, {:array, :string})
      add(:study_program_codes, {:array, :string})

      add(:study_id, references(:studies, on_delete: :nothing))

      timestamps()
    end

    create(unique_index(:eligibility_criteria, [:study_id]))
  end
end
