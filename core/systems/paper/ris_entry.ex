defmodule Systems.Paper.RISEntry do
  @moduledoc """
  Struct representing a bibliographic entry from a RIS file.
  Used to maintain consistent data structure across the import pipeline.
  """

  @enforce_keys [:status]
  defstruct [
    # "new" | "existing" | "error"
    :status,
    :title,
    :subtitle,
    # List of author strings
    :authors,
    :year,
    :date,
    :doi,
    :journal,
    :abbreviated_journal,
    :volume,
    :pages,
    :abstract,
    # List of keywords
    :keywords,
    # Only for existing papers
    :paper_id,
    # Error message for failed parsing
    :error
  ]

  @type status :: :new | :existing | :error

  @type t :: %__MODULE__{
          status: String.t(),
          title: String.t() | nil,
          subtitle: String.t() | nil,
          authors: list(String.t()),
          year: String.t() | nil,
          date: String.t() | nil,
          doi: String.t() | nil,
          journal: String.t() | nil,
          abbreviated_journal: String.t() | nil,
          volume: String.t() | nil,
          pages: String.t() | nil,
          abstract: String.t() | nil,
          keywords: list(String.t()) | nil,
          paper_id: integer() | nil,
          error: String.t() | nil
        }

  @doc """
  Creates a new RISEntry for a new paper
  """
  def new_paper(attrs) do
    %__MODULE__{
      status: "new",
      title: attrs[:title],
      subtitle: attrs[:subtitle],
      authors: attrs[:authors] || [],
      year: attrs[:year],
      date: attrs[:date],
      doi: attrs[:doi],
      journal: attrs[:journal],
      abbreviated_journal: attrs[:abbreviated_journal],
      volume: attrs[:volume],
      pages: attrs[:pages],
      abstract: attrs[:abstract],
      keywords: attrs[:keywords] || []
    }
  end

  @doc """
  Creates a new RISEntry for an existing paper
  """
  def existing_paper(attrs, paper_id) do
    %__MODULE__{
      status: "existing",
      title: attrs[:title],
      subtitle: attrs[:subtitle],
      authors: attrs[:authors] || [],
      year: attrs[:year],
      date: attrs[:date],
      doi: attrs[:doi],
      journal: attrs[:journal],
      abbreviated_journal: attrs[:abbreviated_journal],
      volume: attrs[:volume],
      pages: attrs[:pages],
      abstract: attrs[:abstract],
      keywords: attrs[:keywords] || [],
      paper_id: paper_id
    }
  end

  @doc """
  Creates a new RISEntry for a parsing error.
  Accepts either a string or a structured error map.
  """
  def error(error_data) when is_binary(error_data) do
    %__MODULE__{
      status: "error",
      error: error_data
    }
  end

  def error(%{message: _message} = error_data) when is_map(error_data) do
    %__MODULE__{
      status: "error",
      # Store the full structure
      error: error_data
    }
  end

  def error(error_data) do
    # Fallback for other formats
    %__MODULE__{
      status: "error",
      error: error_data
    }
  end

  @doc """
  Converts the struct to a map for JSON encoding in database
  """
  def to_map(%__MODULE__{} = ref) do
    ref
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  @doc """
  Creates a RISEntry from a map with atom keys
  (as returned by Ecto when loading JSON from database)
  """
  def from_map(map) when is_map(map) do
    # First normalize to atom keys if we have string keys
    map =
      if map_has_string_keys?(map) do
        atomize_keys(map)
      else
        map
      end

    status = map[:status]

    base = %__MODULE__{
      status: status,
      title: map[:title],
      subtitle: map[:subtitle],
      authors: map[:authors] || [],
      year: map[:year],
      date: map[:date],
      doi: map[:doi],
      journal: map[:journal],
      abbreviated_journal: map[:abbreviated_journal],
      volume: map[:volume],
      pages: map[:pages],
      abstract: map[:abstract],
      keywords: map[:keywords] || []
    }

    case status do
      "existing" ->
        %{base | paper_id: map[:paper_id]}

      "error" ->
        %{base | error: map[:error]}

      _ ->
        base
    end
  end

  defp map_has_string_keys?(map) do
    map
    |> Map.keys()
    |> Enum.any?(&is_binary/1)
  end

  defp atomize_keys(map) do
    map
    |> Enum.reduce(%{}, fn
      {k, v}, acc when is_binary(k) ->
        # Convert string keys to atoms, skip unknown keys
        try do
          Map.put(acc, String.to_existing_atom(k), v)
        rescue
          ArgumentError -> acc
        end

      {k, v}, acc ->
        Map.put(acc, k, v)
    end)
  end

  @doc """
  Processes entries to extract error entries and convert them to RISEntryError structs.
  Handles various error formats that may come from RIS parsing.
  """
  def process_entry_errors(entries) do
    alias Systems.Paper.RISEntryError

    entries
    |> Enum.map(&from_map/1)
    |> Enum.filter(&(&1.status == "error"))
    |> Enum.map(fn %{error: error} ->
      case error do
        %{"line" => _, "error" => _} = map -> RISEntryError.from_map(map)
        %{line: _, error: _} = map -> RISEntryError.from_map(map)
        %{"line_number" => _, "message" => _} = map -> RISEntryError.from_map(map)
        %{line_number: _, message: _} = map -> RISEntryError.from_map(map)
        # Fallback for other formats
        _ -> error
      end
    end)
  end
end
