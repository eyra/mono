defmodule Core.Repo.Migrations.AddPlatformNameToAffiliate do
  use Ecto.Migration

  def change do
    alter table(:affiliate) do
      add(:platform_name, :string)
    end
  end
end
