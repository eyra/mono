defmodule Mica.Repo.Migrations.UpgradeObanToV14 do
  use Ecto.Migration

  def up do
    Oban.Migrations.up(version: 14, prefix: prefix() || "public")
  end

  def down do
    Oban.Migrations.down(version: 14, prefix: prefix() || "public")
  end
end
