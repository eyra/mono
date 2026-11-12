defmodule Systems.Workflow.RequiredItemsMigrationTest do
  use Mica.DataCase, async: false

  alias Systems.Assignment
  alias Systems.Workflow

  @version 20_261_109_120_000
  @migration Mica.Repo.Migrations.AddRequiredToWorkflowItems
  @migration_file "priv/repo/migrations/20261109120000_add_required_to_workflow_items.exs"

  setup_all do
    unless Code.ensure_loaded?(@migration), do: Code.compile_file(@migration_file)
    :ok
  end

  setup do
    data_donation =
      Assignment.Factories.create_template_assignment(:data_donation, [
        :manual,
        :request_manual,
        :download_manual,
        :donate,
        :questionnaire
      ])

    questionnaire =
      Assignment.Factories.create_template_assignment(:questionnaire, [:manual, :questionnaire])

    # The data as it was before this migration: no required column
    :ok = Ecto.Migrator.down(Repo, @version, @migration, log: false, migration_lock: false)
    :ok = Ecto.Migrator.up(Repo, @version, @migration, log: false, migration_lock: false)

    %{data_donation: data_donation, questionnaire: questionnaire}
  end

  for special <- [:manual, :request_manual, :download_manual] do
    @special special
    test "turns off the #{special} of a data donation workflow", %{data_donation: assignment} do
      assert %{required: false} = item(assignment, @special)
    end
  end

  for special <- [:donate, :questionnaire] do
    @special special
    test "keeps the #{special} item of a data donation workflow required", %{
      data_donation: assignment
    } do
      assert %{required: true} = item(assignment, @special)
    end
  end

  for special <- [:manual, :questionnaire] do
    @special special
    test "keeps the #{special} item of a questionnaire workflow required", %{
      questionnaire: assignment
    } do
      assert %{required: true} = item(assignment, @special)
    end
  end

  defp item(%{workflow_id: workflow_id}, special) do
    workflow_id
    |> Workflow.Public.list_items([:tool_ref])
    |> Enum.find(&(&1.tool_ref.special == special))
  end
end
