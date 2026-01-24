defmodule Frameworks.UserState do
  @moduledoc """
  Helpers for working with scoped user state in LiveViews.

  User state is stored as a nested map with namespaces. Each embedded view
  can have its own namespace (e.g., `[:manual, 123]`) that scopes its portion
  of the global user state.

  ## Example

  Given global user_state:
      %{manual: %{123 => %{chapter_id: 5}}}

  And namespace `[:manual, 123]`, the scoped user_state is:
      %{chapter_id: 5}

  ## Storage Key Format

  User state is persisted to localStorage using URI-like keys:
      next://user-{user_id}@{domain}/{path}/{name}

  Example: `next://user-2@localhost/assignment/5/crew/5/task`

  ## Schema Validation

  User state is validated against versioned Ecto schemas. When loading state
  from localStorage:

  1. Parse flat localStorage format to nested attrs
  2. Validate against schema ladder (newest to oldest)
  3. Apply migrators to upgrade old formats

  This ensures stale data from previous versions is properly handled.
  """

  alias Frameworks.Concept.LiveContext
  alias Frameworks.UserState.SchemaRegistry
  alias Frameworks.UserState.Storage

  @doc """
  Saves a key/value pair to storage using the configured backend.

  Accepts a namespace and key, builds the full storage key, and delegates to the backend.
  Validates the write against the current schema in dev/test environments.

  ## Examples

      iex> save(socket, %{id: 2}, [:manual, 123], :chapter, 5)
      # Saves to "next://user-2@localhost/manual/123/chapter" with value 5
  """
  def save(socket, user, namespace, key, value) when is_atom(key) do
    SchemaRegistry.validate_write!(namespace, key, value)
    path = namespace ++ [key]
    storage_key = build_storage_key(user, path)
    Storage.save(socket, storage_key, value)
  end

  @doc """
  Extracts a specific key from scoped user_state.

  Uses the namespace from context to scope the user_state before extracting the key.
  """
  def extract_scoped_value(context, key, socket) do
    user_state = LiveContext.retrieve(context, :user_state, socket) || %{}
    namespace = LiveContext.retrieve(context, :user_state_namespace, socket)
    scoped_user_state = scope_user_state(user_state, namespace)
    Map.get(scoped_user_state, key)
  end

  @doc """
  Scopes user_state to a namespace path.

  ## Examples

      iex> scope_user_state(%{manual: %{123 => %{chapter_id: 5}}}, [:manual, 123])
      %{chapter_id: 5}

      iex> scope_user_state(%{chapter_id: 5}, nil)
      %{chapter_id: 5}

      iex> scope_user_state(%{}, [:manual, 123])
      %{}
  """
  def scope_user_state(user_state, nil), do: user_state
  def scope_user_state(user_state, []), do: user_state

  def scope_user_state(user_state, [key | rest]) do
    case Map.get(user_state, key) do
      nil -> %{}
      nested -> scope_user_state(nested, rest)
    end
  end

  defp build_storage_key(%{id: user_id}, path) do
    path_string = Enum.map_join(path, "/", &to_string/1)
    "next://user-#{user_id}@#{domain()}/#{path_string}"
  end

  @doc """
  Returns the domain for storage keys.
  """
  def domain do
    Application.get_env(:core, :domain, "localhost")
  end

  @doc """
  Extracts string value from user_state map.
  """
  def string_value(data, key) do
    Map.get(data, key)
  end

  @doc """
  Extracts integer value from user_state map.
  """
  def integer_value(data, key) do
    if value = Map.get(data, key) do
      try do
        value |> String.to_integer()
      rescue
        ArgumentError -> nil
      end
    else
      nil
    end
  end

  @doc """
  Parses flat localStorage map with URI keys into nested structure.

  Validates against the schema ladder, migrating old formats to current version.
  Returns a nested map structure for use by the application.

  Filters by user_id and converts keys like:
      "next://user-10@localhost/assignment/5/crew/5/task" => "4"

  Into nested structure:
      %{assignment: %{5 => %{crew: %{5 => %{task: 4}}}}}

  ## Examples

      iex> parse_user_state(%{"next://user-10@localhost/assignment/5/crew/3/task" => "4"}, 10)
      %{assignment: %{5 => %{crew: %{3 => %{task: 4}}}}}
  """
  def parse_user_state(flat_state, user_id) when is_map(flat_state) do
    case SchemaRegistry.parse(flat_state, user_id) do
      {:ok, validated_state} ->
        # Convert validated schema struct to nested map format used by application
        SchemaRegistry.current_schema().to_nested_map(validated_state)

      {:error, _reason} ->
        # Fall back to empty state on validation failure
        %{}
    end
  end

  def parse_user_state(_, _), do: %{}

  @doc """
  Legacy parser that doesn't validate against schemas.

  Use `parse_user_state/2` instead for validated parsing.
  This is kept for backwards compatibility during migration.
  """
  def parse_user_state_legacy(flat_state, user_id) when is_map(flat_state) do
    prefix = "next://user-#{user_id}@#{domain()}/"

    flat_state
    |> Enum.filter(fn {key, _value} -> String.starts_with?(key, prefix) end)
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      path = parse_storage_key(key)
      put_in_path(acc, path, parse_value(value))
    end)
  end

  def parse_user_state_legacy(_, _), do: %{}

  defp parse_storage_key(key) do
    # Extract path from "next://user-10@localhost/assignment/5/crew/5/task"
    case String.split(key, "/", parts: 4) do
      [_protocol, _empty, _user_host, path] ->
        path
        |> String.split("/")
        |> Enum.map(&parse_path_segment/1)

      _ ->
        []
    end
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

  defp put_in_path(map, [key], value) do
    Map.put(map, key, value)
  end

  defp put_in_path(map, [key | rest], value) do
    nested = Map.get(map, key, %{})
    Map.put(map, key, put_in_path(nested, rest, value))
  end
end
