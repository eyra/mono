defmodule Systems.Assignment.ConsentPeriodsMigrationTest do
  use Mica.DataCase, async: false

  alias Systems.Assignment

  @version 20_261_111_150_000
  @migration Mica.Repo.Migrations.AddConsentPeriodsToAssignments
  @migration_file "priv/repo/migrations/20261111150000_add_consent_periods_to_assignments.exs"

  setup_all do
    unless Code.ensure_loaded?(@migration), do: Code.compile_file(@migration_file)
    :ok
  end

  describe "down" do
    test "keeps the agreement of an assignment that older code switched off and on after this code switched it off" do
      assignment =
        Assignment.Factories.create_assignment_with_consent()
        |> Assignment.Factories.consent_since(300)
        |> put_closed_period(300, 200)
        |> Assignment.Factories.switch_consent_off_as_old_code()
        |> Assignment.Factories.switch_consent_on_as_old_code(100)

      assert Assignment.Model.consent_on?(assignment)

      migrate_down()

      assert linked_agreement_id(assignment) == assignment.consent_agreement_id
    end

    test "unlinks the agreement of an assignment whose consent is off" do
      assignment =
        Assignment.Factories.create_assignment_with_consent()
        |> Assignment.Factories.consent_since(300)
        |> Assignment.Factories.switch_consent(:off)

      migrate_down()

      assert linked_agreement_id(assignment) == nil
    end

    test "keeps the agreement of an assignment whose consent was switched on again" do
      assignment =
        Assignment.Factories.create_assignment_with_consent()
        |> Assignment.Factories.consent_since(300)
        |> Assignment.Factories.switch_consent(:off)
        |> Assignment.Factories.switch_consent(:on)

      migrate_down()

      assert linked_agreement_id(assignment) == assignment.consent_agreement_id
    end

    test "keeps the agreement of an assignment whose consent was never switched" do
      assignment = Assignment.Factories.create_assignment_with_consent()

      migrate_down()

      assert linked_agreement_id(assignment) == assignment.consent_agreement_id
    end
  end

  defp put_closed_period(assignment, started_ago, ended_ago) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    assignment
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:consent_periods, [
      %Assignment.ConsentPeriodModel{
        started_at: NaiveDateTime.add(now, -started_ago),
        ended_at: NaiveDateTime.add(now, -ended_ago)
      }
    ])
    |> Repo.update!()
  end

  defp migrate_down do
    :ok = Ecto.Migrator.down(Repo, @version, @migration, log: false, migration_lock: false)
  end

  defp linked_agreement_id(%{id: id}) do
    %{rows: [[agreement_id]]} =
      Repo.query!("SELECT consent_agreement_id FROM assignments WHERE id = $1", [id])

    agreement_id
  end
end
