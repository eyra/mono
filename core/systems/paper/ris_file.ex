defmodule Systems.Paper.RISFile do
  @moduledoc """
    Module for extracting papers from a RIS file.
    See: https://en.wikipedia.org/wiki/RIS_(file_format)
  """

  require Logger

  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Systems.Paper

  @tag_regex Regex.compile!("([A-Z0-9]{2})  - (.*)")

  @type_of_reference_tag "TY"
  @type_of_reference_values ["JOUR", "JFULL", "ABST", "INPR", "CPAPER", "THES"]

  @year_tag "PY"
  @date_tag "DA"

  @title_tag "TI"
  @primary_title_tag "T1"
  @secundary_title_tag "T2"

  @abbreviated_journal "J2"

  @author_tag "AU"
  @primary_author_tag "A1"
  @secondary_author_tag "A2"
  @tertiary_author_tag "A3"
  @subsidiary_quaternary_author_tag "A4"
  @quinary_auhtor_tag "A5"
  @website_editor_tag "A6"

  @do_tag "DO"
  @di_tag "DI"
  @doi_tag "DOI"

  @abstract_tag "AB"

  @keyword_tag "KW"

  @end_of_reference_tag "ER"

  def process(reference_file_id) when is_integer(reference_file_id) do
    Logger.info("[Paper] Processing papers: started")

    Paper.Public.get_reference_file!(
      reference_file_id,
      Paper.ReferenceFileModel.preload_graph(:down)
    )
    |> process()
  end

  def process(%{file: %{ref: nil}}) do
    Logger.error("[Paper] Processing papers: failed -> source file is missing")
  end

  def process(%{file: %{ref: ref}} = reference_file) do
    with {:ok, _, _, client_ref} <- :hackney.request(:get, ref),
         {:ok, body} <- client_ref |> :hackney.body() do
      process(reference_file, body)
      Logger.info("[Paper] Processing papers: ended")
    else
      error ->
        Logger.error("[Paper] Processing papers: failed -> #{inspect(error)}")
    end
  end

  def process(reference_file, body) when is_binary(body) do
    chunk_fun = fn element, acc ->
      if String.starts_with?(element, @end_of_reference_tag) do
        {:cont, Enum.reverse([element | acc]), []}
      else
        {:cont, [element | acc]}
      end
    end

    after_func = fn
      [] ->
        {:cont, []}

      _ ->
        raise Paper.RISError,
          message: "[Paper] Processing papers: invalid RIS file, missing 'ER -' tag"
    end

    body
    |> String.split(~r{(\r\n|\r|\n)})
    |> Enum.reject(&(&1 == ""))
    |> Enum.chunk_while([], chunk_fun, after_func)
    |> Enum.to_list()
    |> tap(fn references ->
      Logger.info("[Paper] Processing papers: #{Enum.count(references)} references")
    end)
    |> Enum.map(&parse_reference(&1))
    |> Enum.map(&prepare_reference(&1, reference_file))
    |> Enum.with_index()
    |> create_transaction(reference_file)
    |> Repo.transaction()
  end

  def prepare_reference({:ok, {paper, raw}}, reference_file) do
    ris = Paper.Public.prepare_ris(raw)
    file_paper = Paper.Public.prepare_file_paper(reference_file)
    %{paper: paper, ris: ris, file_paper: file_paper}
  end

  def prepare_reference({:error, {error, _raw}}, reference_file) do
    file_error = Paper.Public.prepare_file_error(reference_file, error)
    %{file_error: file_error}
  end

  def parse_reference(lines) do
    raw = Enum.join(lines, "")
    type_of_reference = extract_type_of_reference(lines)

    case validate_type_of_reference(type_of_reference) do
      :ok ->
        {:ok, {parse_paper(lines), raw}}

      {:error, error} ->
        Logger.error("[Paper] Extracting papers: error: #{inspect(error)}")
        {:error, {parse_error(lines, error), raw}}
    end
  end

  # PARSING

  def parse_paper(lines) do
    Paper.Public.prepare_paper(
      extract_year(lines),
      extract_date(lines),
      extract_abbreviated_journal(lines),
      extract_doi(lines),
      extract_title(lines),
      extract_subtitle(lines),
      extract_authors(lines),
      extract_abstract(lines),
      extract_keywords(lines)
    )
  end

  def parse_error(_lines, error) do
    Paper.Public.prepare_error(error)
  end

  def validate_type_of_reference(type_of_reference) do
    if Enum.member?(@type_of_reference_values, type_of_reference) do
      :ok
    else
      {:error, {:unsupported_type_of_reference, type_of_reference}}
    end
  end

  # EXTRACTION

  def extract_type_of_reference(lines), do: extract(lines, @type_of_reference_tag)

  def extract_year(lines), do: extract(lines, @year_tag)

  def extract_date(lines), do: extract(lines, @date_tag)

  def extract_abbreviated_journal(lines), do: extract(lines, @abbreviated_journal)

  def extract_abstract(lines), do: extract(lines, @abstract_tag)

  def extract_title(lines), do: extract(lines, [@title_tag, @primary_title_tag])

  def extract_subtitle(lines), do: extract(lines, [@secundary_title_tag])

  def extract_authors(lines),
    do:
      extract_list(lines, [
        @author_tag,
        @primary_author_tag,
        @secondary_author_tag,
        @tertiary_author_tag,
        @subsidiary_quaternary_author_tag,
        @quinary_auhtor_tag,
        @website_editor_tag
      ])

  @doc """
    Extracts the Digial Object Identifier (DOI) from the RIS file.
    The DOI is a unique identifier for a paper.
  """
  def extract_doi(lines), do: extract(lines, [@doi_tag, @do_tag, @di_tag])

  def extract_keywords(lines), do: extract_list(lines, @keyword_tag)

  defp extract(lines, tag) when is_binary(tag) do
    extract(lines, [tag])
  end

  defp extract(lines, tags) when is_list(tags) do
    Enum.find_value(lines, fn line ->
      {tag, value} = split(line)

      if Enum.member?(tags, tag) do
        value
      else
        nil
      end
    end)
  end

  defp extract_list(lines, tag) when is_binary(tag) do
    extract_list(lines, [tag])
  end

  defp extract_list(lines, tags) when is_list(tags) do
    Enum.reduce(lines, [], fn line, acc ->
      {tag, value} = split(line)

      if Enum.member?(tags, tag) do
        acc ++ [value]
      else
        acc
      end
    end)
  end

  defp split(line) do
    case Regex.run(@tag_regex, line) do
      [_, tag, value] -> {tag, value}
      _ -> raise Paper.RISError, message: "Invalid RIS file, line: '#{line}'"
    end
  end

  # PERSISTENCE

  defp create_transaction(references_with_index, reference_file) do
    references_with_index
    |> Enum.reduce(Multi.new(), fn {reference, index}, multi ->
      persist_reference(reference, index, multi)
    end)
    |> Multi.update(
      :paper_reference_file,
      reference_file |> Paper.ReferenceFileModel.changeset(%{status: :processed})
    )
    |> Signal.Public.multi_dispatch({:paper_reference_file, :updated})
  end

  defp persist_reference(%{paper: paper, ris: ris, file_paper: file_paper}, index, multi) do
    multi
    |> Multi.insert({:paper, index}, paper)
    |> Multi.insert({:ris, index}, fn %{{:paper, ^index} => paper} ->
      Paper.Public.finalize_ris(ris, paper)
    end)
    |> Multi.insert({:file_paper, index}, fn %{{:paper, ^index} => paper} ->
      Paper.Public.finalize_file_paper(file_paper, paper)
    end)
  end

  defp persist_reference(%{file_error: file_error}, index, multi) do
    Multi.insert(multi, {:file_error, index}, file_error)
  end
end
