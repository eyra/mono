defmodule Mica.RegistryRefsMigrationTest do
  @moduledoc """
  code-registry, release 1: the sync trigger, the checks and the indexes of
  `20261117140000`..`20261117140300`, and the backfill. Raw SQL, because these test
  what the database does whichever code writes.
  """
  use Mica.DataCase, async: false

  @backfill_version 20_261_117_140_200
  @backfill Mica.Repo.Migrations.BackfillRegistryRefs
  @backfill_file "priv/repo/migrations/20261117140200_backfill_registry_refs.exs"

  setup_all do
    unless Code.ensure_loaded?(@backfill), do: Code.compile_file(@backfill_file)
    :ok
  end

  describe "the sync trigger" do
    test "older code sets a per-type column: the type and id follow" do
      tool = doc_tool()
      ref = insert_ref(%{"document_tool_id" => tool})

      assert %{"tool_type" => "document", "tool_id" => ^tool, "document_tool_id" => ^tool} = ref
    end

    test "newer code sets the type and id: the per-type column follows" do
      tool = doc_tool()
      ref = insert_ref(%{"tool_type" => "document", "tool_id" => tool})

      assert %{"document_tool_id" => ^tool, "alliance_tool_id" => nil} = ref
    end

    test "an unrelated update changes neither side" do
      tool = doc_tool()
      %{"id" => id} = insert_ref(%{"document_tool_id" => tool})

      ref = update_ref(id, "special = 'download_manual'")

      assert %{"tool_type" => "document", "tool_id" => ^tool, "document_tool_id" => ^tool} = ref
    end

    test "older code moves a ref to another tool: the type and id follow" do
      %{"id" => id} = insert_ref(%{"document_tool_id" => doc_tool()})
      other = doc_tool()

      assert %{"tool_type" => "document", "tool_id" => ^other} =
               update_ref(id, "document_tool_id = #{other}")
    end

    test "newer code moves a ref to another tool: the per-type column follows" do
      %{"id" => id} = insert_ref(%{"tool_type" => "document", "tool_id" => doc_tool()})
      other = doc_tool()

      assert %{"document_tool_id" => ^other} = update_ref(id, "tool_id = #{other}")
    end

    test "a type without a per-type column keeps its type and id" do
      ref = insert_ref(%{"tool_type" => "onyx", "tool_id" => 1})

      assert %{"tool_type" => "onyx", "tool_id" => 1, "document_tool_id" => nil} = ref
    end

    test "a ref of the reserved type none stays none on an update" do
      %{"id" => id} = insert_ref(%{"tool_type" => "none"})

      assert %{"tool_type" => "none", "tool_id" => nil, "document_tool_id" => nil} =
               update_ref(id, "special = 'manual'")
    end

    test "older code sets a project item's per-type column: the type and id follow" do
      endpoint = storage_endpoint()
      item = insert_item(%{"storage_endpoint_id" => endpoint})

      assert %{"item_type" => "storage_endpoint", "item_id" => ^endpoint} = item
    end
  end

  describe "the checks and indexes" do
    test "a tool ref that references nothing is refused" do
      assert_raise Postgrex.Error, ~r/tool_refs_tool_required/, fn -> insert_ref(%{}) end
    end

    test "a real type without an id is refused" do
      assert_raise Postgrex.Error, ~r/tool_refs_tool_required/, fn ->
        insert_ref(%{"tool_type" => "document"})
      end
    end

    test "a project item that holds nothing is refused" do
      assert_raise Postgrex.Error, ~r/project_items_item_required/, fn -> insert_item(%{}) end
    end

    test "a second ref for the same tool is refused" do
      tool = doc_tool()
      insert_ref(%{"document_tool_id" => tool})

      assert_raise Postgrex.Error, ~r/tool_refs_tool_type_tool_id_index/, fn ->
        insert_ref(%{"document_tool_id" => tool})
      end
    end

    test "a second storage item on one project node is refused" do
      node = project_node()
      insert_item(%{"storage_endpoint_id" => storage_endpoint()}, node)

      assert_raise Postgrex.Error, ~r/project_items_storage_per_node_index/, fn ->
        insert_item(%{"storage_endpoint_id" => storage_endpoint()}, node)
      end
    end
  end

  describe "the backfill" do
    setup do
      # Rows as they were before release 1: no type, and no check or trigger to fill one.
      Repo.query!("ALTER TABLE tool_refs DISABLE TRIGGER registry_sync")
      Repo.query!("ALTER TABLE tool_refs DROP CONSTRAINT tool_refs_tool_required")
      :ok
    end

    test "fills the type and id from the per-type column, and none for a row that sets none" do
      tool = doc_tool()
      %{"id" => with_tool} = insert_ref(%{"document_tool_id" => tool})
      %{"id" => empty} = insert_ref(%{})

      rerun_backfill()

      assert %{"tool_type" => "document", "tool_id" => ^tool} = ref(with_tool)
      assert %{"tool_type" => "none", "tool_id" => nil} = ref(empty)
    end

    test "refuses to run when a row sets two per-type columns" do
      insert_ref(%{"document_tool_id" => doc_tool(), "alliance_tool_id" => alliance_tool()})

      assert_raise Postgrex.Error, ~r/tool_refs: 1 rows set 2\+ tool columns/, &rerun_backfill/0
    end
  end

  # --- helpers

  defp rerun_backfill do
    :ok =
      Ecto.Migrator.down(Repo, @backfill_version, @backfill, log: false, migration_lock: false)

    :ok = Ecto.Migrator.up(Repo, @backfill_version, @backfill, log: false, migration_lock: false)
  end

  defp insert_ref(columns) do
    columns = Map.merge(%{"inserted_at" => NaiveDateTime.utc_now()}, columns)
    columns = Map.put(columns, "updated_at", columns["inserted_at"])
    insert("tool_refs", columns)
  end

  defp insert_item(columns, node \\ nil) do
    now = NaiveDateTime.utc_now()

    columns =
      Map.merge(
        %{
          "name" => "item",
          "project_path" => [],
          "node_id" => node || project_node(),
          "inserted_at" => now,
          "updated_at" => now
        },
        columns
      )

    insert("project_items", columns)
  end

  defp insert(table, columns) do
    {names, values} = Enum.unzip(columns)
    placeholders = Enum.map_join(1..length(values), ", ", &"$#{&1}")

    %{rows: [row], columns: cols} =
      Repo.query!(
        "INSERT INTO #{table} (#{Enum.join(names, ", ")}) VALUES (#{placeholders}) RETURNING *",
        values
      )

    Enum.zip(cols, row) |> Map.new()
  end

  defp update_ref(id, set) do
    %{rows: [row], columns: cols} =
      Repo.query!("UPDATE tool_refs SET #{set} WHERE id = $1 RETURNING *", [id])

    Enum.zip(cols, row) |> Map.new()
  end

  defp ref(id) do
    %{rows: [row], columns: cols} = Repo.query!("SELECT * FROM tool_refs WHERE id = $1", [id])
    Enum.zip(cols, row) |> Map.new()
  end

  defp doc_tool, do: Factories.insert!(:document_tool).id
  defp alliance_tool, do: Factories.insert!(:alliance_tool).id
  defp project_node, do: Factories.insert!(:project_node, %{name: "node", project_path: []}).id

  defp storage_endpoint do
    now = NaiveDateTime.utc_now()

    %{rows: [[id]]} =
      Repo.query!(
        "INSERT INTO storage_endpoints (inserted_at, updated_at) VALUES ($1, $1) RETURNING id",
        [now]
      )

    id
  end
end
