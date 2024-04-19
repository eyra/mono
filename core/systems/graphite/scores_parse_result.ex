defmodule Systems.Graphite.ScoresParseResult do
  alias __MODULE__, as: Result
  alias Systems.Graphite

  require Logger

  @base_fields ["submission-id", "url", "ref"]

  defstruct [:csv, :duplicate_count, :rejected, :valid]

  def from_file(local_path, leaderboard) do
    local_path
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> from_lines(leaderboard)
  end

  def from_url(csv_url, leaderboard) do
    %{body: body} = HTTPoison.get!(csv_url)

    lines =
      body
      |> String.split("\n")
      |> CSV.decode(headers: true)

    from_lines(lines, leaderboard)
  end

  def from_lines(lines, leaderboard) do
    submission_map =
      Graphite.Public.get_submissions(leaderboard.tool)
      |> Enum.reduce(%{}, fn submission, acc ->
        {url, ref} = Graphite.SubmissionModel.repo_url_and_ref(submission)
        Map.put(acc, submission.id, {url, ref})
      end)

    records =
      lines
      |> to_records()
      |> Stream.map(fn record -> check_fields(record, leaderboard.metrics, :missing_metric) end)
      |> Stream.map(fn record -> check_fields(record, @base_fields, :missing_base_field) end)
      |> Stream.map(fn record -> convert_ints(record, ["submission-id"]) end)
      |> Stream.map(fn record -> convert_floats(record, leaderboard.metrics) end)
      |> Stream.map(fn record -> check_submission(record, submission_map) end)
      |> Enum.map(fn record -> check_url_ref(record, submission_map) end)

    {valid, rejected} =
      Enum.split_with(records, fn
        {_, _, []} -> true
        {_, _, [_ | _]} -> false
      end)

    %Result{csv: lines, rejected: rejected, valid: valid}
  end

  defp to_records(lines) do
    lines
    |> Enum.with_index(1)
    |> Enum.map(&unpack/1)
  end

  defp unpack({{:ok, line}, line_nr}), do: {line_nr, line, []}

  defp unpack({{:error, error}, line_nr}) do
    Logger.error("Unable to unpack csv line: #{error}")
    {line_nr, nil, [:parse_error]}
  end

  defp check_fields({_, nil, _} = record, _fields, _error), do: record

  defp check_fields({line_nr, line, errors} = record, fields, error) do
    if Enum.all?(fields, fn field -> Map.has_key?(line, field) end) do
      record
    else
      {line_nr, line, [error | errors]}
    end
  end

  defp check_submission({_, nil, _} = record, _submission_map), do: record

  defp check_submission({line_nr, line, errors}, submission_map) do
    if Map.has_key?(submission_map, line["submission-id"]) do
      submission = Map.get(submission_map, line["submission-id"])
      {line_nr, Map.put(line, "submission_record", submission), errors}
    else
      {line_nr, line, [:missing_submission | errors]}
    end
  end

  defp check_url_ref({_, nil, _} = record, _submission_map), do: record

  defp check_url_ref({_, _, [:missing_submission | _]} = record, _), do: record

  defp check_url_ref({line_nr, line, errors} = record, submission_map) do
    {url, ref} = submission_map[line["submission-id"]]

    if line["url"] == url and line["ref"] == ref do
      record
    else
      {line_nr, line, [:incorrect_url | errors]}
    end
  end

  def convert_ints({_, nil, _} = record), do: record

  def convert_ints({line_nr, line, errors}, fields) do
    updated =
      fields
      |> Enum.reduce(
        line,
        fn field, acc ->
          Map.update!(acc, field, fn value -> String.to_integer(value) end)
        end
      )

    {line_nr, updated, errors}
  end

  def convert_floats({_, nil, _} = record), do: record

  def convert_floats({line_nr, line, errors}, fields) do
    updated =
      fields
      |> Enum.reduce(
        line,
        fn field, acc ->
          Map.update!(acc, field, fn value -> String.to_float(value) end)
        end
      )

    {line_nr, updated, errors}
  end
end
