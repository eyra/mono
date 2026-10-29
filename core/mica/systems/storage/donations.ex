defmodule Systems.Storage.Donations do
  @moduledoc """
  Reads the participant, key, session and tool from the name of a stored
  donation (`Storage.Filename.generate/1`, e.g.
  `assignment=5_task=9_participant=p1_source=cogflex_key=run1/summary.json`),
  and groups donations per participant. Next sets every part except the key,
  which the tool chooses; so the key is read last and never searched for the
  other parts.
  """

  @participant ~r/(?:\A|_)participant=([A-Za-z0-9_-]+?)(?=_source=|\z)/
  @source ~r/(?:\A|_)source=(.+)\z/
  @task ~r/(?:\A|_)task=(.+?)(?=_participant=|_source=|\z)/

  def participant(path) when is_binary(path), do: capture(@participant, identifiers(path))

  def key(path) when is_binary(path) do
    case String.split(path, "_key=", parts: 2) do
      [_identifiers, key] -> String.replace_suffix(key, ".json", "")
      [_] -> key_at_start(path)
    end
  end

  @doc "The part of the key before the first `/`: one run of a tool."
  def session(path) when is_binary(path) do
    case key(path) do
      nil -> nil
      key -> key |> String.split("/", parts: 2) |> hd()
    end
  end

  def tool(path) when is_binary(path) do
    identifiers = identifiers(path)
    capture(@source, identifiers) || capture(@task, identifiers)
  end

  @doc "Files per participant, sorted on participant; files without one come last."
  def by_participant(files) when is_list(files) do
    files
    |> Enum.group_by(fn %{path: path} -> participant(path) end)
    |> Enum.sort_by(fn {participant, _} -> {is_nil(participant), participant} end)
  end

  def summaries(files) when is_list(files) do
    files
    |> by_participant()
    |> Enum.map(fn {participant, files} -> summary(participant, files) end)
  end

  defp summary(participant, files) do
    paths = Enum.map(files, fn %{path: path} -> path end)

    %{
      participant: participant,
      sessions: paths |> Enum.map(&session/1) |> Enum.uniq() |> Enum.count(),
      tools: paths |> Enum.map(&tool/1) |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort(),
      files: Enum.count(files),
      last_donation: last_donation(files)
    }
  end

  defp last_donation(files) do
    files
    |> Enum.map(fn %{timestamp: timestamp} -> timestamp end)
    |> Enum.reject(&is_nil/1)
    |> Enum.max(DateTime, fn -> nil end)
  end

  # Everything before the key, without the extension.
  defp identifiers(path) do
    case String.split(path, "_key=", parts: 2) do
      [identifiers, _key] -> identifiers
      [_] -> if key_at_start(path), do: "", else: String.replace_suffix(path, ".json", "")
    end
  end

  defp key_at_start("key=" <> key), do: String.replace_suffix(key, ".json", "")
  defp key_at_start(_path), do: nil

  defp capture(regex, identifiers) do
    case Regex.run(regex, identifiers, capture: :all_but_first) do
      [value] -> value
      nil -> nil
    end
  end
end
