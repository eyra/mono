defmodule Link.Repo.Migrations.AddAuthNodeToSurveyTool do
  use Ecto.Migration

  def change do
    alter table(:survey_tools) do
      add(:auth_node_id, references(:authorization_nodes), null: false)
    end
  end
end
