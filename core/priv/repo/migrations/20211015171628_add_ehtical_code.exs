defmodule Core.Repo.Migrations.AddEhticalCode do
  use Ecto.Migration

  def up do
    alter table(:survey_tools) do
      add(:ethical_code, :string)
    end
  end

  def down do
    alter table(:survey_tools) do
      remove(:ethical_code)
    end
  end
end
