defmodule Frameworks.UserState.SchemaRegistry do
  @moduledoc """
  Schema ladder for validating and migrating user state.

  The schema ladder is an ordered list of {schema, migrator} tuples, from newest
  to oldest. When parsing localStorage data:

  1. **Climb down**: Try each schema from newest to oldest until one validates
  2. **Climb up**: Apply migrators back up the ladder to reach current version

  ## Example

  Ladder: [{V2, nil}, {V1, V1ToV2}]

  If data validates as V1:
  - V2 validation fails (climb down)
  - V1 validation succeeds (stop climbing)
  - Apply V1ToV2 migrator (climb up)
  - Return V2 data

  ## Adding New Schema Versions

  1. Create new schema module (e.g., `Schemas.V3`)
  2. Create migrator module (e.g., `Migrators.V2ToV3`)
  3. Update ladder: `[{V3, nil}, {V2, V2ToV3}, {V1, V1ToV2}]`
  """

  require Logger

  alias Frameworks.UserState.Schemas.V1
  alias Frameworks.UserState.Schemas.V2
  alias Frameworks.UserState.Migrators.V1ToV2
  alias Frameworks.UserState.Transformer

  @doc """
  Returns the schema ladder from newest to oldest.

  Each tuple is {schema_module, migrator_module}.
  The first (newest) schema has nil migrator since it's the target.
  """
  def ladder do
    [
      {V2, nil},
      {V1, V1ToV2}
    ]
  end

  @doc """
  Returns the current (newest) schema module.
  """
  def current_schema do
    [{schema, _} | _] = ladder()
    schema
  end

  @doc """
  Parses and validates flat localStorage state.

  Returns `{:ok, validated_state}` with the state migrated to the current version,
  or `{:error, reason}` if the state is invalid for all schemas.

  ## Examples

      iex> parse(%{"next://user-10@localhost/assignment/5/crew/3/task" => "4"}, 10)
      {:ok, %V2{assignments: [%{id: 5, crews: [%{id: 3, task: 4}]}]}}
  """
  def parse(flat_state, user_id) do
    {:ok, attrs, conflicts} = Transformer.flat_to_nested(flat_state, user_id)
    log_conflicts(conflicts)
    validate_and_migrate(attrs)
  end

  @doc """
  Validates attrs against the schema ladder and migrates to current version.

  Tries schemas from newest to oldest (climbing down), then applies migrators
  back up to reach the current version.
  """
  def validate_and_migrate(attrs) do
    ladder = ladder()

    case climb_down(attrs, ladder, 0) do
      {:ok, validated, schema_index} ->
        climb_up(validated, ladder, schema_index)

      {:error, :no_matching_schema} ->
        Logger.warning("[UserState.SchemaRegistry] No matching schema for attrs: #{inspect(attrs)}")
        {:error, :invalid_user_state}
    end
  end

  # Climb down the ladder trying each schema until one validates
  defp climb_down(_attrs, [], _index) do
    {:error, :no_matching_schema}
  end

  defp climb_down(attrs, [{schema, _migrator} | rest], index) do
    case schema.validate(attrs) do
      {:ok, validated} ->
        if index > 0 do
          Logger.info("[UserState.SchemaRegistry] Matched schema #{schema.version()} (will migrate)")
        end
        {:ok, validated, index}

      {:error, _changeset} ->
        climb_down(attrs, rest, index + 1)
    end
  end

  # Climb back up applying migrators
  defp climb_up(state, _ladder, 0) do
    # Already at current version
    {:ok, state}
  end

  defp climb_up(state, ladder, index) do
    # Get schemas from index-1 down to 0 (climbing up means applying migrators in reverse order)
    migrators =
      ladder
      |> Enum.take(index)
      |> Enum.map(fn {_schema, migrator} -> migrator end)
      |> Enum.reverse()

    migrated_state =
      Enum.reduce(migrators, state, fn migrator, current_state ->
        Logger.info("[UserState.SchemaRegistry] Applying migrator: #{inspect(migrator)}")
        migrator.migrate(current_state)
      end)

    {:ok, migrated_state}
  end

  defp log_conflicts([]), do: :ok

  defp log_conflicts(conflicts) do
    Logger.warning(
      "[UserState.SchemaRegistry] Dropped conflicting paths: #{inspect(conflicts)}"
    )
  end

  @doc """
  Validates that a write operation matches the current schema.

  In dev/test: raises on invalid writes
  In prod: logs warning and allows the write

  This is called before saving to localStorage to catch schema violations early.
  """
  def validate_write!(namespace, key, value) do
    # Build a minimal attrs map for the path being written
    attrs = build_attrs_for_path(namespace, key, value)

    case current_schema().validate(attrs) do
      {:ok, _} ->
        :ok

      {:error, changeset} ->
        path = namespace ++ [key]
        handle_invalid_write(path, value, changeset)
    end
  end

  defp build_attrs_for_path([:assignment, aid, :crew, cid], key, value) do
    crew = %{id: cid} |> Map.put(key, value)
    %{
      assignments: [%{id: aid, crews: [crew]}],
      manuals: []
    }
  end

  defp build_attrs_for_path([:manual, mid], key, value) do
    manual = %{id: mid} |> Map.put(key, value)
    %{
      assignments: [],
      manuals: [manual]
    }
  end

  defp build_attrs_for_path(path, _key, _value) do
    Logger.warning("[UserState.SchemaRegistry] Unknown path pattern: #{inspect(path)}")
    %{assignments: [], manuals: []}
  end

  defp handle_invalid_write(path, value, changeset) do
    message = "[UserState.SchemaRegistry] Invalid write to #{inspect(path)} with value #{inspect(value)}: #{inspect(changeset.errors)}"

    if raise_on_invalid_write?() do
      raise ArgumentError, message
    else
      Logger.warning(message)
      :ok
    end
  end

  defp raise_on_invalid_write? do
    Application.get_env(:core, :user_state_raise_on_invalid_write, false)
  end
end
