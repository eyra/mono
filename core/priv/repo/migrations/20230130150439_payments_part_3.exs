defmodule Core.Repo.Migrations.PaymentsPart3 do
  use Ecto.Migration

  def up do
    alter table(:pools) do
      modify(:director, :string, null: false)
    end
  end

  def down do
    alter table(:pools) do
      modify(:director, :string, null: true)
    end
  end
end
