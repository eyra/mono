defmodule Core.Repo.Migrations.ExtendSurveyTool do
  use Ecto.Migration

  def up do
    alter table(:user_profiles) do
      add(:title, :string)
      add(:url, :string)
    end

    alter table(:survey_tools) do
      add(:subtitle, :string)
      add(:expectations, :string)
      add(:banner_photo_url, :string)
      add(:banner_title, :string)
      add(:banner_subtitle, :string)
      add(:banner_url, :string)
    end
  end

  def down do
    alter table(:user_profiles) do
      remove(:title)
      remove(:url)
    end

    alter table(:survey_tools) do
      remove(:subtitle)
      remove(:expectations)
      remove(:banner_photo_url)
      remove(:banner_title)
      remove(:banner_subtitle)
      remove(:banner_url)
    end
  end
end
