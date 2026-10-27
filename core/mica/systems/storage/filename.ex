defmodule Systems.Storage.Filename do
  @moduledoc """
  Generates filenames for storage backends.
  """

  @doc """
  Generates a filename from an identifier list.

  Example: assignment=5_task=9.json
  """
  def generate(identifier) do
    identifier
    |> Enum.reject(fn [_key, value] -> is_nil(value) or value == "" end)
    |> Enum.map_join("_", fn [key, value] -> "#{key}=#{value}" end)
    |> then(&"#{&1}.json")
  end

  @doc """
  Generates a unique filename with timestamp.
  """
  def generate_unique(identifier) do
    base = generate(identifier)
    timestamp = System.system_time(:millisecond)
    String.replace(base, ".json", "_#{timestamp}.json")
  end

  @doc """
  Returns true when every identifier value is nil, an integer, or a string
  without control characters (such as CR, LF or NUL). Donation keys, tasks and
  sources never need them. Any other value, such as a list or a map, is refused.
  """
  def valid_identifier?(identifier) do
    Enum.all?(identifier, fn [_key, value] -> valid_value?(value) end)
  end

  @doc """
  Turns a filename into a single URL path segment: `/` and `\\` become `_`, so
  the file stays in the endpoint's folder, and every character outside RFC 3986
  `pchar` is percent-encoded. The server decodes it back to the same name.
  A whole name of `.` or `..` stays a dot segment; `generate/1` never returns
  one, as its names always end in `.json`.
  """
  def url_segment(filename) when is_binary(filename) do
    filename
    |> String.replace(["/", "\\"], "_")
    |> URI.encode(&path_char?/1)
  end

  defp valid_value?(nil), do: true
  defp valid_value?(value) when is_integer(value), do: true

  defp valid_value?(value) when is_binary(value),
    do: not String.match?(value, ~r/[\x00-\x1F\x7F]/)

  defp valid_value?(_value), do: false

  defp path_char?(char), do: URI.char_unreserved?(char) or char in ~c"!$&'()*+,;=:@"
end
