defmodule Core.Repo.Migrations.SplitSurveyPromotion do
  use Ecto.Migration

  def change do
    alter table(:survey_tools) do
      remove(:title)
      remove(:subtitle)
      remove(:expectations)
      remove(:description)
      remove(:published_at)
      remove(:themes)
      remove(:image_id)
      remove(:marks)
      remove(:banner_photo_url)
      remove(:banner_title)
      remove(:banner_subtitle)
      remove(:banner_url)
      remove(:phone_enabled)
      remove(:tablet_enabled)
      remove(:desktop_enabled)

      add(:devices, {:array, :string})
      add(:promotion_id, references(:promotions))
      add(:content_node_id, references(:content_nodes), null: false)
    end

    drop(index(:survey_tool_tasks, [:survey_tool_id]))
    drop(unique_index(:survey_tool_tasks, [:user_id, :survey_tool_id]))

    alter table(:survey_tool_tasks) do
      remove(:survey_tool_id)
      add(:tool_id, references(:survey_tools, on_delete: :delete_all), null: false)
    end

    create(index(:survey_tool_tasks, [:tool_id]))
    create(unique_index(:survey_tool_tasks, [:user_id, :tool_id]))
  end
end
