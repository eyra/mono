defmodule Core.Repo.Migrations.AddCrew do
  use Ecto.Migration

  def up do
    create table(:crews) do
      add(:reference_type, :string, null: false)
      add(:reference_id, :bigint, null: false)
      add(:next_public_id, :bigint, default: 0)
      add(:auth_node_id, references(:authorization_nodes), null: false)

      timestamps()
    end

    create(unique_index(:crews, [:reference_type, :reference_id]))

    create table(:crew_members) do
      add(:crew_id, references(:crews, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:public_id, :bigint)

      timestamps()
    end

    create(index(:crew_members, [:crew_id]))
    create(unique_index(:crew_members, [:user_id, :crew_id]))

    create table(:crew_tasks) do
      add(:status, :string, null: false)
      add(:crew_id, references(:crews, on_delete: :delete_all), null: false)
      add(:member_id, references(:crew_members, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:crew_tasks, [:status]))
    create(index(:crew_tasks, [:crew_id]))

    execute("""
    CREATE OR REPLACE FUNCTION set_crew_members_public_id()
         RETURNS TRIGGER AS $$
    BEGIN
      UPDATE crews INTO NEW.public_id
        SET next_public_id=next_public_id+1 WHERE crews.id=NEW.crew_id RETURNING next_public_id;

      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER crew_members_public_id
    BEFORE INSERT ON crew_members
    FOR EACH ROW EXECUTE FUNCTION set_crew_members_public_id();
    """)

    create(unique_index(:crew_members, [:crew_id, :public_id]))
  end

  def down do
    execute "DROP TRIGGER IF EXISTS crew_members_public_id ON crew_members;"
    execute "DROP FUNCTION IF EXISTS set_crew_members_public_id() CASCADE;"

    drop(index(:crew_members, [:crew_id, :public_id]))


    drop(index(:crew_tasks, [:status]))
    drop(index(:crew_tasks, [:crew_id]))
    drop(table(:crew_tasks))

    drop(index(:crew_members, [:crew_id]))
    drop(index(:crew_members, [:user_id, :crew_id]))
    drop(table(:crew_members))

    drop(index(:crews, [:reference_type, :reference_id]))
    drop(table(:crews))
  end
end
