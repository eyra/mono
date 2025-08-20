defmodule Systems.Paper.RISEntryError do
  @moduledoc """
  Struct representing a parsing error for a specific line in a RIS file.
  """

  @enforce_keys [:line, :error]
  defstruct [:line, :error, :content]

  @type t :: %__MODULE__{
          line: integer(),
          error: String.t(),
          content: String.t() | nil
        }

  @doc """
  Creates a new RISEntryError
  """
  def new(line, error, content \\ nil) when is_integer(line) and is_binary(error) do
    %__MODULE__{
      line: line,
      error: error,
      content: content
    }
  end

  @doc """
  Creates a RISEntryError from a map with string or atom keys.
  Handles both line/error and line_number/message field names.
  """
  def from_map(%{"line" => line, "error" => error} = map) do
    %__MODULE__{
      line: line,
      error: error,
      content: map["content"]
    }
  end

  def from_map(%{line: line, error: error} = map) do
    %__MODULE__{
      line: line,
      error: error,
      content: map[:content]
    }
  end

  def from_map(%{"line_number" => line, "message" => message} = map) do
    %__MODULE__{
      line: line,
      error: message,
      content: map["line_content"] || map["content"]
    }
  end

  def from_map(%{line_number: line, message: message} = map) do
    %__MODULE__{
      line: line,
      error: message,
      content: map[:line_content] || map[:content]
    }
  end

  @doc """
  Converts the struct to a map for JSON encoding
  """
  def to_map(%__MODULE__{} = error) do
    base = %{
      "line" => error.line,
      "error" => error.error
    }

    if error.content do
      Map.put(base, "content", error.content)
    else
      base
    end
  end
end
