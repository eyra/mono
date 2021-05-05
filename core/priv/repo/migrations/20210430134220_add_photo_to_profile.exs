defmodule Core.Repo.Migrations.AddPhotoToProfile do
  use Ecto.Migration

  def up do
    alter table(:user_profiles) do
      add(:photo_url, :string)
    end
  end

  def down do
    alter table(:survey_tools) do
      remove(:photo_url)
    end
  end
end
