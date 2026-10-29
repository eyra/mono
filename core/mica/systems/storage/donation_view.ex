defmodule Systems.Storage.DonationView do
  @moduledoc """
  Turns a donation into blocks a page can show without knowing the tool that
  made it:

  1. an object whose values are scalars, or lists of scalars, is a table with one row;
  2. a list of such objects is a table, with the union of their keys as columns;
  3. anything else is a tree, whose fields of that kind form a one-row table and
     whose other fields are blocks of their own.

  Columns keep the order of the fields in the donation.
  """

  alias Jason.OrderedObject
  alias Systems.Storage

  @max_bytes 5_000_000

  @doc """
  Reads a donation the endpoint lists, so a path never reaches the filesystem
  unchecked. Returns the listed file with its decoded `donation`.
  """
  # shortcut: reads files on the local filesystem only (S3 lists a URL source);
  # read S3 objects too before this leaves the spike.
  def read(endpoint, path) when is_binary(path) do
    case Enum.find(Storage.Public.list_files(endpoint), fn %{path: listed} -> listed == path end) do
      nil -> {:error, :not_found}
      %{size: size} when size > @max_bytes -> {:error, :too_large}
      %{source: {:file, file}} = listed -> read_file(listed, file)
      _ -> {:error, :unsupported}
    end
  end

  defp read_file(listed, file) do
    with {:ok, json} <- File.read(file),
         {:ok, donation} <- decode(json) do
      {:ok, Map.put(listed, :donation, donation)}
    else
      _ -> {:error, :unreadable}
    end
  end

  def decode(json) when is_binary(json), do: Jason.decode(json, objects: :ordered_objects)

  def blocks(%OrderedObject{values: fields} = object) do
    if flat?(object) do
      table([fields])
    else
      {scalars, nested} = Enum.split_with(fields, fn {_key, value} -> cell?(value) end)

      {:tree, scalar_table(scalars),
       Enum.map(nested, fn {key, value} -> {key, blocks(value)} end)}
    end
  end

  def blocks(list) when is_list(list) do
    if list != [] and Enum.all?(list, &flat?/1) do
      table(Enum.map(list, fn %OrderedObject{values: fields} -> fields end))
    else
      {:list, Enum.map(list, &blocks/1)}
    end
  end

  def blocks(value), do: {:value, value}

  defp scalar_table([]), do: nil
  defp scalar_table(scalars), do: table([scalars])

  defp table(records) do
    columns =
      records
      |> Enum.flat_map(fn fields -> Enum.map(fields, fn {key, _} -> key end) end)
      |> Enum.uniq()

    rows =
      Enum.map(records, fn fields ->
        values = Map.new(fields)
        Enum.map(columns, &Map.get(values, &1))
      end)

    {:table, columns, rows}
  end

  defp flat?(%OrderedObject{values: fields}),
    do: Enum.all?(fields, fn {_key, value} -> cell?(value) end)

  defp flat?(_value), do: false

  # A list of scalars, such as the options a trial offered, fits in one cell.
  defp cell?(value) when is_list(value), do: Enum.all?(value, &scalar?/1)
  defp cell?(value), do: scalar?(value)

  defp scalar?(value),
    do: is_binary(value) or is_number(value) or is_boolean(value) or is_nil(value)
end
