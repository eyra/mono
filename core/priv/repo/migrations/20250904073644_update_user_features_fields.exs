defmodule Core.Repo.Migrations.UpdateUserFeaturesFields do
  use Ecto.Migration

  def up do
    alter table(:user_features) do
      add(:birth_year, :integer)
      remove(:dominant_hand)
      remove(:native_language)
    end

    alter table(:eligibility_criteria) do
      remove(:dominant_hands)
      remove(:native_languages)
    end
  end

  def down do
    alter table(:user_features) do
      remove(:birth_year)
      add(:dominant_hand, :string)
      add(:native_language, :string)
    end

    alter table(:eligibility_criteria) do
      add(:dominant_hands, {:array, :string})
      add(:native_languages, {:array, :string})
    end
  end
end
