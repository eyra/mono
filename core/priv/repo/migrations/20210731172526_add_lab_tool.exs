defmodule Core.Repo.Migrations.AddLabTool do
  use Ecto.Migration

  def up do
    create table(:lab_tools) do
      add(:auth_node_id, references(:authorization_nodes), null: false)
      add(:content_node_id, references(:content_nodes), null: false)
      add(:study_id, references(:studies), null: false)
      add(:promotion_id, references(:promotions))

      timestamps()
    end

    create table(:lab_time_slots) do
      add(:tool_id, references(:lab_tools), null: false)
      add(:location, :text)
      add(:start_time, :timestamptz)
      add(:number_of_seats, :integer, default: 1, null: false)

      timestamps()
    end

    create table(:lab_reservations, primary_key: false) do
      add(:user_id, references(:users), null: false, primary_key: true)
      add(:time_slot_id, references(:lab_time_slots), null: false, primary_key: true)
      add(:status, :text)
      timestamps()
    end

    create(
      index(:lab_time_slots, [:start_time],
        comment: "Allow fast lookup of time slots (notifications)"
      )
    )

    create(
      constraint(:lab_time_slots, :number_of_seats_must_be_greater_than_zero,
        check: "number_of_seats > 0",
        comment: "A slot without option to reserve makes no sense"
      )
    )

    create(
      constraint(:lab_time_slots, :start_time_must_be_reasonable,
        check: "start_time > date '2000-01-01' and start_time < date '2500-01-01'",
        comment: "Time slots in the past or distant future are considered an error."
      )
    )
  end
end
