defmodule Link.Repo.Migrations.AddDisplaynameUserProfile do
  use Ecto.Migration

  def change do
    alter table(:user_profiles) do
      add(:displayname, :string)
    end
  end
end
