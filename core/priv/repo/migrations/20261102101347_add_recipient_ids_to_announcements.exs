defmodule Mica.Repo.Migrations.AddRecipientIdsToAnnouncements do
  use Ecto.Migration

  def change do
    alter table(:announcement) do
      add(:recipient_ids, {:array, :bigint}, null: false, default: [])
    end
  end
end
