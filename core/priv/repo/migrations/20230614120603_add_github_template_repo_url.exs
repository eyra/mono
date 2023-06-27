defmodule Core.Repo.Migrations.AddGithubTemplateRepoUrl do
  use Ecto.Migration

  def up do
    alter table(:benchmark_tools) do
      add(:template_repo, :string)
    end
  end

  def down do
    alter table(:benchmark_tools) do
      remove(:template_repo)
    end
  end
end
