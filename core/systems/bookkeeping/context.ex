defmodule Systems.Bookkeeping.Context do
  @moduledoc """
  The bookkeeping system.
  """

  alias Core.Repo
  alias Systems.Bookkeeping.{BookModel, EntryModel, LineModel}
  import Ecto.Query
  import Ecto.Changeset
  alias Ecto.Multi

  def enter(%{lines: lines} = entry) when is_list(lines) do
    with :ok <- validate_entry_balance(lines),
         :ok <- validate_either_credit_or_debit_is_used(lines) do
      case update_records(entry) do
        {:ok, _} -> :ok
        {:error, :entry, changeset, _} -> handle_entry_error(changeset)
      end
    end
  end

  def balance(book) do
    case Repo.get_by(BookModel, identifier: to_identifier(book)) do
      nil -> %{debit: 0, credit: 0}
      %{balance_debit: debit, balance_credit: credit} -> %{debit: debit, credit: credit}
    end
  end

  def list_entries(book) do
    book_identifier = to_identifier(book)

    from(line in LineModel,
      join: entry in EntryModel,
      on: entry.id == line.entry_id,
      join: book in BookModel,
      on: book.id == line.book_id,
      where: book.identifier == ^book_identifier,
      preload: [:book, :entry]
    )
    |> Repo.all()
    |> Enum.chunk_by(& &1.entry.id)
    |> Enum.map(fn [%{entry: entry} | _] = lines ->
      %{
        idempotence_key: entry.idempotence_key,
        journal_message: entry.journal_message,
        lines:
          Enum.map(lines, fn line ->
            Map.take(line, [:debit, :credit])
          end)
      }
    end)
  end

  defp update_records(%{lines: lines} = entry) do
    Multi.new()
    |> update_books(lines)
    |> insert_entry(entry)
    |> insert_lines(lines)
    |> Repo.transaction()
  end

  defp insert_line(multi, %{book: book} = line) do
    multi
    |> Multi.run("line-#{to_identifier(book)}", fn repo, %{entry: entry} = changes ->
      repo.insert(
        %LineModel{}
        |> cast(line, [:debit, :credit])
        |> put_assoc(:book, Map.fetch!(changes, book))
        |> put_assoc(:entry, entry)
      )
    end)
  end

  defp insert_lines(multi, lines) do
    Enum.reduce(lines, multi, fn line, multi ->
      insert_line(multi, line)
    end)
  end

  defp insert_entry(multi, entry) do
    multi
    |> Multi.insert(
      :entry,
      %EntryModel{}
      |> cast(entry, [:idempotence_key, :journal_message])
      |> validate_required([:idempotence_key, :journal_message])
      |> unique_constraint(:idempotence_key)
    )
  end

  defp handle_entry_error(%{errors: errors}) do
    if Keyword.has_key?(errors, :idempotence_key) do
      {:error, :idempotence_key_conflict}
    else
      {:error, :unexpected_entity_error}
    end
  end

  defp update_books(multi, lines) when is_list(lines) do
    Enum.reduce(lines, multi, fn line, multi ->
      update_book(multi, line)
    end)
  end

  defp update_book(multi, %{book: book} = line) do
    debit = Map.get(line, :debit, 0)
    credit = Map.get(line, :credit, 0)

    multi
    |> Multi.insert(
      book,
      %BookModel{
        identifier: to_identifier(book),
        balance_debit: debit,
        balance_credit: credit
      },
      conflict_target: :identifier,
      on_conflict: [inc: [balance_debit: debit, balance_credit: credit]]
    )
  end

  defp to_identifier({type, id}) do
    [Atom.to_string(type), Integer.to_string(id)]
  end

  defp to_identifier(type) when is_atom(type) do
    [Atom.to_string(type)]
  end

  defp validate_entry_balance(lines) when is_list(lines) do
    {debit, credit} =
      Enum.reduce(lines, {0, 0}, fn entry, {debit, credit} ->
        {debit + Map.get(entry, :debit, 0), credit + Map.get(entry, :credit, 0)}
      end)

    if debit == credit do
      :ok
    else
      {:error, :unbalanced_lines}
    end
  end

  defp validate_either_credit_or_debit_is_used(lines) when is_list(lines) do
    if Enum.any?(lines, &(Map.get(&1, :debit) && Map.get(&1, :credit))) do
      {:error, :entry_with_both_debit_and_credit}
    else
      :ok
    end
  end
end
