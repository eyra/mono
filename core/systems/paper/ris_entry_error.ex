defmodule Systems.Paper.RISEntryError do
  @moduledoc """
  Struct representing a parsing error for a specific line in a RIS file.
  """

  @enforce_keys [:line, :message]
  defstruct [:line, :message, :content]

  @type t :: %__MODULE__{
          line: integer(),
          message: String.t(),
          content: String.t() | nil
        }

  @doc """
  Creates a new RISEntryError
  """
  def new(line, message, content \\ nil) when is_integer(line) and is_binary(message) do
    %__MODULE__{
      line: line,
      message: message,
      content: content
    }
  end

  @doc """
  Creates a RISEntryError from a map with string or atom keys.
  Handles both line/message and line_number/message field names.
  """
  def from_map(%{"line" => line, "message" => message} = map) do
    %__MODULE__{
      line: line,
      message: message,
      content: map["content"]
    }
  end

  def from_map(%{line: line, message: message} = map) do
    %__MODULE__{
      line: line,
      message: message,
      content: map[:content]
    }
  end

  def from_map(%{"line_number" => line, "message" => message} = map) do
    %__MODULE__{
      line: line,
      message: message,
      content: map["line_content"] || map["content"]
    }
  end

  def from_map(%{line_number: line, message: message} = map) do
    %__MODULE__{
      line: line,
      message: message,
      content: map[:line_content] || map[:content]
    }
  end

  @doc """
  Converts the struct to a map for JSON encoding
  """
  def to_map(%__MODULE__{} = error) do
    base = %{
      "line" => error.line,
      "message" => error.message
    }

    if error.content do
      Map.put(base, "content", error.content)
    else
      base
    end
  end
end
