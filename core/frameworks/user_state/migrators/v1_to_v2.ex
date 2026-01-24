defmodule Frameworks.UserState.Migrators.V1ToV2 do
  @moduledoc """
  Migrates UserState from V1 to V2 schema.

  ## V1 Legacy Patterns

  V1 allowed storing leaf values at intermediate paths:
  - `assignment/<id>` => integer (stored crew_id directly)

  This caused conflicts when V2 introduced:
  - `assignment/<id>/crew/<id>/task` => integer

  ## Migration Strategy

  V1 data at intermediate paths is dropped during migration because:
  - The meaning has changed (old crew_id vs new nested structure)
  - There's no reliable way to migrate the data
  - Fresh state is safer than potentially corrupted state

  The dropped values are logged for audit purposes.
  """

  require Logger

  alias Frameworks.UserState.Schemas.V1
  alias Frameworks.UserState.Schemas.V2

  @doc """
  Migrates a validated V1 state to V2 format.

  Drops legacy leaf values at intermediate paths and logs them.
  """
  def migrate(%V1{} = v1_state) do
    dropped = collect_dropped_values(v1_state)
    log_dropped_values(dropped)

    attrs = %{
      assignments: migrate_assignments(v1_state.assignments),
      manuals: migrate_manuals(v1_state.manuals)
    }

    case V2.validate(attrs) do
      {:ok, v2_state} ->
        v2_state

      {:error, changeset} ->
        # This shouldn't happen if migration logic is correct
        Logger.error(
          "[V1ToV2] Migration produced invalid V2 state: #{inspect(changeset.errors)}"
        )

        # Return empty valid state as fallback
        {:ok, empty_state} = V2.validate(%{assignments: [], manuals: []})
        empty_state
    end
  end

  defp migrate_assignments(assignments) do
    Enum.map(assignments, fn assignment ->
      %{
        id: assignment.id,
        crews: migrate_crews(assignment.crews || [])
      }
    end)
  end

  defp migrate_crews(crews) do
    Enum.map(crews, fn crew ->
      %{
        id: crew.id,
        task: crew.task
      }
    end)
  end

  defp migrate_manuals(manuals) do
    Enum.map(manuals, fn manual ->
      %{
        id: manual.id,
        chapter: manual.chapter,
        page: manual.page
      }
    end)
  end

  defp collect_dropped_values(%V1{assignments: assignments}) do
    Enum.flat_map(assignments, fn assignment ->
      if assignment.value do
        [{[:assignment, assignment.id], assignment.value}]
      else
        []
      end
    end)
  end

  defp log_dropped_values([]), do: :ok

  defp log_dropped_values(dropped) do
    Logger.warning(
      "[V1ToV2] Dropped legacy values during migration: #{format_dropped(dropped)}"
    )
  end

  defp format_dropped(dropped) do
    dropped
    |> Enum.map(fn {path, value} ->
      path_str = Enum.map_join(path, "/", &to_string/1)
      "#{path_str}=#{value}"
    end)
    |> Enum.join(", ")
  end
end
