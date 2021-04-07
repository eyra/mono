defmodule Core.Repo.Migrations.ExtendStudySurveyToolData do
  use Ecto.Migration


  def up do
    alter table(:survey_tools) do
      add(:themes, {:array, :string})
      add(:image_url, :string)
      add(:marks, {:array, :string})
      add(:reward_currency, :string)
      add(:reward_value, :integer)
    end
  end

  def down do
    alter table(:survey_tools) do
      remove(:themes)
      remove(:image_url)
      remove(:marks)
      remove(:reward_currency)
      remove(:reward_value)
    end
  end
end
