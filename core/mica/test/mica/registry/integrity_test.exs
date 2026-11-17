defmodule Mica.Registry.IntegrityTest do
  # put_composition/1 changes the composition for every process.
  use Mica.DataCase, async: false

  import ExUnit.CaptureLog

  alias Mica.Registry.Integrity

  # A registered type whose table rows don't exist for the ids the test stores.
  defmodule PhantomTool do
    use Mica.Tool
    def type, do: "phantom"
    def schema, do: Systems.Document.ToolModel
    def prepare(_attrs, _context), do: nil
    def view, do: nil
  end

  setup do
    previous = Mica.SaaS.put_composition(%{})
    on_exit(fn -> Mica.SaaS.put_composition(previous) end)
  end

  test "every reference holds" do
    Factories.insert!(:tool_ref, %{document_tool: Factories.insert!(:document_tool)})

    counts = Integrity.check()

    assert counts.tool_refs.missing_target["document"] == 0
    assert counts.tool_refs.unknown_type == 0
    refute Integrity.problems?(counts)
  end

  test "a ref whose target row is missing is counted" do
    Mica.SaaS.put_composition(tools: Mica.Tools.all() ++ [PhantomTool])
    insert_ref("phantom", 999_999_999)

    counts = Integrity.check()

    assert counts.tool_refs.missing_target["phantom"] == 1
    assert Integrity.problems?(counts)
  end

  test "a ref whose type the composition doesn't have is counted" do
    insert_ref("retired_type", 1)

    counts = Integrity.check()

    assert counts.tool_refs.unknown_type == 1
    assert Integrity.problems?(counts)
  end

  test "a ref of the reserved type none is counted, and is no problem" do
    insert_ref("none", nil)

    counts = Integrity.check()

    assert counts.tool_refs.none == 1
    assert counts.tool_refs.unknown_type == 0
    refute Integrity.problems?(counts)
  end

  test "a tool ref without a workflow item is counted, and is no problem" do
    Factories.insert!(:tool_ref, %{document_tool: Factories.insert!(:document_tool)})

    counts = Integrity.check()

    assert counts.tool_refs.without_workflow_item == 1
    refute Integrity.problems?(counts)
  end

  describe "the daily worker" do
    test "logs an error for a reference that doesn't hold, and removes nothing" do
      insert_ref("retired_type", 1)

      log =
        capture_log([level: :error], fn -> Mica.Registry.IntegrityWorker.perform(%Oban.Job{}) end)

      assert log =~ "[Registry.Integrity] references that don't hold"
      assert %{rows: [[1]]} = Repo.query!("SELECT count(*) FROM tool_refs")
    end

    test "logs no error when every reference holds" do
      log =
        capture_log([level: :error], fn -> Mica.Registry.IntegrityWorker.perform(%Oban.Job{}) end)

      refute log =~ "[Registry.Integrity]"
    end
  end

  defp insert_ref(type, id) do
    Repo.query!(
      "INSERT INTO tool_refs (tool_type, tool_id, inserted_at, updated_at) VALUES ($1, $2, now(), now())",
      [type, id]
    )
  end
end
