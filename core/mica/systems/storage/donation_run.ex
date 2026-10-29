defmodule Systems.Storage.DonationRun do
  @moduledoc """
  The records a summary summarizes: the trials of the same run of the same
  participant, per Prompt. A Prompt result (`<run>/<flow>/<prompt>`) gives all its
  records; where it is missing, its trials (`<run>/<flow>/<prompt>/<index>`) do.
  """

  alias Jason.OrderedObject
  alias Systems.Storage

  @doc "Whether a donation is the summary of a run (`<run>/summary`)."
  def summary?(path) when is_binary(path) do
    case Storage.Donations.key(path) do
      nil -> false
      key -> match?([_run, "summary"], String.split(key, "/"))
    end
  end

  @doc "The Prompts of the run, in donation order, each with its records as field lists."
  # shortcut: reads files on the local filesystem only, as DonationView.read/2 does.
  def prompts(endpoint, path) when is_binary(path) do
    endpoint |> Storage.Public.list_files() |> prompts_in(path)
  end

  @doc "As `prompts/2`, from a file listing the caller already has."
  def prompts_in(files, path) when is_list(files) and is_binary(path) do
    [identifiers, _key] = String.split(path, "_key=", parts: 2)
    prefix = "#{identifiers}_key=#{Storage.Donations.session(path)}/"

    files
    |> Enum.filter(fn %{path: listed} -> String.starts_with?(listed, prefix) end)
    |> Enum.flat_map(&prompt_file/1)
    |> Enum.group_by(fn {label, _kind, _file} -> label end)
    |> Enum.map(fn {label, files} -> prompt(label, files) end)
    |> Enum.sort_by(fn %{donated_at: donated_at, label: label} -> {donated_at, label} end)
    |> Enum.reject(fn %{records: records} -> records == [] end)
    |> Enum.map(&Map.delete(&1, :donated_at))
  end

  defp prompt_file(%{path: path} = file) do
    case path |> Storage.Donations.key() |> String.split("/") do
      [_run, flow, prompt] -> [{"#{flow} / #{prompt}", :result, file}]
      [_run, flow, prompt, index] -> [{"#{flow} / #{prompt}", {:trial, index}, file}]
      _ -> []
    end
  end

  defp prompt(label, files) do
    %{label: label, donated_at: donated_at(files), records: records(files)}
  end

  defp donated_at(files) do
    files
    |> Enum.map(fn {_label, _kind, %{timestamp: timestamp}} -> unix(timestamp) end)
    |> Enum.min()
  end

  defp unix(%DateTime{} = timestamp), do: DateTime.to_unix(timestamp)
  defp unix(_timestamp), do: 0

  # A result without records (missing, or overwritten by another donation) falls back to the trials.
  defp records(files) do
    case Enum.find(files, fn {_label, kind, _file} -> kind == :result end) do
      {_label, :result, file} -> with [] <- result_records(file), do: trial_records(files)
      nil -> trial_records(files)
    end
  end

  defp result_records(file) do
    case decode(file) do
      {:ok, %OrderedObject{} = result} -> result |> field("responses") |> objects()
      _ -> []
    end
  end

  defp trial_records(files) do
    files
    |> Enum.filter(fn {_label, kind, _file} -> match?({:trial, _}, kind) end)
    |> Enum.sort_by(fn {_label, {:trial, index}, _file} -> trial_index(index) end)
    |> Enum.flat_map(fn {_label, _kind, file} ->
      case decode(file) do
        {:ok, %OrderedObject{} = trial} -> trial |> field("response") |> List.wrap() |> objects()
        _ -> []
      end
    end)
  end

  defp trial_index(index) do
    case Integer.parse(index) do
      {number, ""} -> number
      _ -> 0
    end
  end

  defp field(%OrderedObject{values: fields}, name) do
    Enum.find_value(fields, fn {key, value} -> if key == name, do: value end)
  end

  defp objects(list) when is_list(list) do
    for %OrderedObject{values: fields} <- list, do: fields
  end

  defp objects(_value), do: []

  defp decode(%{source: {:file, file}}) do
    with {:ok, json} <- File.read(file), do: Storage.DonationView.decode(json)
  end

  defp decode(_file), do: {:error, :unsupported}
end
