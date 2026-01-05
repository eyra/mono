defmodule Core.Repo.Migrations.AddBirthYearFieldsToEligibilityCriteria do
  use Ecto.Migration

  def up do
    alter table(:eligibility_criteria) do
      add(:min_birth_year, :integer)
      add(:max_birth_year, :integer)
    end
  end

  def down do
    alter table(:eligibility_criteria) do
      remove(:min_birth_year)
      remove(:max_birth_year)
    end
  end
end
