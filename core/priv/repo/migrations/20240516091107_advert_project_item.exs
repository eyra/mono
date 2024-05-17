defmodule Core.Repo.Migrations.AdvertProjectItem do
  use Ecto.Migration

  def up do
    alter table(:project_items) do
      add(:advert_id, references(:adverts))
    end

    drop_if_exists(constraint(:project_items, :must_have_at_least_one_reference))

    create(
      constraint(:project_items, :must_have_at_least_one_reference,
        check: """
        assignment_id != null or
        advert_id != null or
        leaderboard_id != null
        """
      )
    )
  end

  def down do
    drop_if_exists(constraint(:project_items, :must_have_at_least_one_reference))

    create(
      constraint(:project_items, :must_have_at_least_one_reference,
        check: """
        assignment_id != null or
        leaderboard_id != null
        """
      )
    )

    alter table(:project_items) do
      remove(:advert_id)
    end
  end
end
