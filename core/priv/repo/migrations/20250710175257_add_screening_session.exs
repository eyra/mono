defmodule Core.Repo.Migrations.AddScreeningSession do
  use Ecto.Migration

  def change do
    create table(:zircon_screening_session) do
      add(:identifier, :string)
      add(:agent_state, :map)
      add(:invalidated_at, :naive_datetime)

      add(:tool_id, references(:zircon_screening_tool), null: false)
      add(:user_id, references(:users), null: false)

      timestamps()
    end

    create(unique_index(:zircon_screening_session, [:tool_id, :user_id]))
    create(index(:zircon_screening_session, [:tool_id]))
    create(index(:zircon_screening_session, [:user_id]))
  end
end
