defmodule Core.Repo.Migrations.ReplaceImageUrlWithImageId do
  use Ecto.Migration

  def up do
    alter table(:survey_tools) do
      remove(:image_url)
      add(:image_id, :text)
    end
  end

  def down do
    alter table(:survey_tools) do
      remove(:image_id)
      add(:image_url, :string)
    end
  end
end
