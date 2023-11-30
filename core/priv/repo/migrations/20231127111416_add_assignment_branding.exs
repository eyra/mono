defmodule Core.Repo.Migrations.AddAssignmentBranding do
  use Ecto.Migration

  def up do
    alter table(:assignment_info) do
      add(:title, :string)
      add(:subtitle, :string)
      add(:image_id, :text)
      add(:logo_url, :string)
    end
  end

  def down do
    alter table(:assignment_info) do
      remove(:title)
      remove(:subtitle)
      remove(:image_id)
      remove(:logo_url)
    end
  end
end
