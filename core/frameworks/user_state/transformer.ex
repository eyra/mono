defmodule Frameworks.UserState.Transformer do
  @moduledoc """
  Transforms between flat localStorage format and nested schema format.

  ## Flat Format (localStorage)

  Keys are URI-like strings:
      "next://user-10@localhost/assignment/5/crew/3/task" => "4"

  ## Nested Format (for schemas)

  Nested maps with lists for embeds_many:
      %{
        assignments: [%{id: 5, crews: [%{id: 3, task: 4}]}],
        manuals: []
      }

  ## Path Conflicts

  When localStorage contains conflicting paths (e.g., both `assignment/5`
  and `assignment/5/crew/3/task`), this transformer detects the conflict
  and returns information about it for the schema registry to handle.
  """

  require Logger

  @doc """
  Transforms flat localStorage state to nested schema format.

  Returns `{:ok, attrs, conflicts}` where:
  - `attrs` is the nested structure suitable for schema validation
  - `conflicts` is a list of `{path, value}` tuples that couldn't be placed

  ## Examples

      iex> flat = %{"next://user-10@localhost/assignment/5/crew/3/task" => "4"}
      iex> Transformer.flat_to_nested(flat, 10)
      {:ok, %{assignments: [%{id: 5, crews: [%{id: 3, task: 4}]}], manuals: []}, []}
  """
  def flat_to_nested(flat_state, user_id) when is_map(flat_state) do
    prefix = "next://user-#{user_id}@#{domain()}/"

    {attrs, conflicts} =
      flat_state
      |> Enum.filter(fn {key, _} -> String.starts_with?(key, prefix) end)
      |> Enum.map(fn {key, value} ->
        path = parse_storage_key(key, prefix)
        {path, parse_value(value)}
      end)
      |> build_nested_attrs()

    {:ok, attrs, conflicts}
  end

  def flat_to_nested(_, _), do: {:ok, empty_attrs(), []}

  @doc """
  Transforms nested schema state back to flat localStorage format.

  Used when we need to re-save migrated state to localStorage.
  """
  def nested_to_flat(%{assignments: assignments, manuals: manuals}, user_id) do
    prefix = "next://user-#{user_id}@#{domain()}/"

    assignment_entries =
      Enum.flat_map(assignments, fn %{id: aid, crews: crews} ->
        Enum.flat_map(crews, fn %{id: cid, task: task} ->
          if task do
            [{"#{prefix}assignment/#{aid}/crew/#{cid}/task", to_string(task)}]
          else
            []
          end
        end)
      end)

    manual_entries =
      Enum.flat_map(manuals, fn %{id: mid, chapter: chapter, page: page} ->
        entries = []
        entries = if chapter, do: [{"#{prefix}manual/#{mid}/chapter", to_string(chapter)} | entries], else: entries
        entries = if page, do: [{"#{prefix}manual/#{mid}/page", to_string(page)} | entries], else: entries
        entries
      end)

    Map.new(assignment_entries ++ manual_entries)
  end

  # Build nested attrs from list of {path, value} tuples
  defp build_nested_attrs(entries) do
    {attrs, conflicts} =
      Enum.reduce(entries, {empty_attrs(), []}, fn {path, value}, {acc, conflicts} ->
        case insert_at_path(acc, path, value) do
          {:ok, updated} -> {updated, conflicts}
          {:conflict, reason} ->
            Logger.warning("[UserState.Transformer] Conflict at #{inspect(path)}: #{reason}")
            {acc, [{path, value} | conflicts]}
        end
      end)

    {attrs, Enum.reverse(conflicts)}
  end

  defp empty_attrs, do: %{assignments: [], manuals: []}

  # Insert value at path, handling the schema structure
  defp insert_at_path(attrs, [:assignment, aid, :crew, cid, key], value) when is_atom(key) do
    {:ok, update_assignment_crew(attrs, aid, cid, key, value)}
  end

  defp insert_at_path(attrs, [:assignment, aid, key], value) when is_atom(key) and is_integer(value) do
    # V1 pattern: leaf value at assignment level
    # Store it as a special "value" field for migration
    {:ok, update_assignment_value(attrs, aid, key, value)}
  end

  defp insert_at_path(attrs, [:assignment, aid], value) when is_integer(value) do
    # V1 pattern: direct value at assignment path
    {:ok, update_assignment_value(attrs, aid, :value, value)}
  end

  defp insert_at_path(attrs, [:manual, mid, key], value) when is_atom(key) do
    {:ok, update_manual(attrs, mid, key, value)}
  end

  defp insert_at_path(_attrs, path, _value) do
    {:conflict, "Unknown path pattern: #{inspect(path)}"}
  end

  # Update assignment crew data
  defp update_assignment_crew(attrs, assignment_id, crew_id, key, value) do
    assignments = attrs[:assignments] || []

    updated_assignments =
      case Enum.find_index(assignments, &(&1[:id] == assignment_id)) do
        nil ->
          # Create new assignment with new crew
          new_crew = %{id: crew_id} |> Map.put(key, value)
          new_assignment = %{id: assignment_id, crews: [new_crew]}
          assignments ++ [new_assignment]

        idx ->
          # Update existing assignment
          assignment = Enum.at(assignments, idx)
          crews = assignment[:crews] || []

          updated_crews =
            case Enum.find_index(crews, &(&1[:id] == crew_id)) do
              nil ->
                # Add new crew
                new_crew = %{id: crew_id} |> Map.put(key, value)
                crews ++ [new_crew]

              crew_idx ->
                # Update existing crew
                List.update_at(crews, crew_idx, &Map.put(&1, key, value))
            end

          List.replace_at(assignments, idx, %{assignment | crews: updated_crews})
      end

    %{attrs | assignments: updated_assignments}
  end

  # Update assignment-level value (V1 legacy pattern)
  defp update_assignment_value(attrs, assignment_id, key, value) do
    assignments = attrs[:assignments] || []

    updated_assignments =
      case Enum.find_index(assignments, &(&1[:id] == assignment_id)) do
        nil ->
          # Create new assignment with value
          new_assignment = %{id: assignment_id, crews: []} |> Map.put(key, value)
          assignments ++ [new_assignment]

        idx ->
          # Update existing assignment
          assignment = Enum.at(assignments, idx)
          List.replace_at(assignments, idx, Map.put(assignment, key, value))
      end

    %{attrs | assignments: updated_assignments}
  end

  # Update manual data
  defp update_manual(attrs, manual_id, key, value) do
    manuals = attrs[:manuals] || []

    updated_manuals =
      case Enum.find_index(manuals, &(&1[:id] == manual_id)) do
        nil ->
          # Create new manual
          new_manual = %{id: manual_id} |> Map.put(key, value)
          manuals ++ [new_manual]

        idx ->
          # Update existing manual
          List.update_at(manuals, idx, &Map.put(&1, key, value))
      end

    %{attrs | manuals: updated_manuals}
  end

  # Parse storage key to path
  defp parse_storage_key(key, prefix) do
    key
    |> String.replace_prefix(prefix, "")
    |> String.split("/")
    |> Enum.map(&parse_path_segment/1)
  end

  defp parse_path_segment(segment) do
    case Integer.parse(segment) do
      {int, ""} -> int
      _ -> String.to_atom(segment)
    end
  end

  defp parse_value(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> value
    end
  end

  defp parse_value(value), do: value

  defp domain do
    Application.get_env(:core, :domain, "localhost")
  end
end
