defmodule Systems.Bookkeeping.Context do
  @moduledoc """
  The bookkeeping system.
  """

  alias Core.Repo
  alias Systems.Bookkeeping.{AccountModel, EntryModel, LineModel}
  import Ecto.Query
  import Ecto.Changeset
  alias Ecto.Multi

  def exists?(idempotence_key) do
    from(entry in EntryModel,
      where: entry.idempotence_key == ^idempotence_key
    )
    |> Repo.exists?()
  end

  def get_entry(idempotence_key, preload \\ [:lines]) do
    from(entry in EntryModel,
      where: entry.idempotence_key == ^idempotence_key,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def enter(%{lines: lines} = entry) when is_list(lines) do
    with :ok <- validate_entry_balance(lines),
         :ok <- validate_either_credit_or_debit_is_used(lines) do
      case update_records(entry) do
        {:ok, _} -> :ok
        {:error, :entry, changeset, _} -> handle_entry_error(changeset)
      end
    end
  end

  def balance(account) do
    case Repo.get_by(AccountModel, identifier: to_identifier(account)) do
      nil -> %{debit: 0, credit: 0}
      %{balance_debit: debit, balance_credit: credit} -> %{debit: debit, credit: credit}
    end
  end

  def list_entries(account) do
    account_identifier = to_identifier(account)

    from(line in LineModel,
      join: entry in EntryModel,
      on: entry.id == line.entry_id,
      join: account in AccountModel,
      on: account.id == line.account_id,
      where: account.identifier == ^account_identifier,
      preload: [:account, :entry]
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

  def account_query(account_template) do
    from(account in AccountModel,
      where: fragment("?::text[] @> ?", account.identifier, ^account_template)
    )
    |> Repo.all()
  end

  defp update_records(%{lines: lines} = entry) do
    Multi.new()
    |> update_accounts(lines)
    |> insert_entry(entry)
    |> insert_lines(lines)
    |> Repo.transaction()
  end

  defp insert_line(multi, %{account: account} = line) do
    multi
    |> Multi.run("line-#{to_identifier(account)}", fn repo, %{entry: entry} = changes ->
      repo.insert(
        %LineModel{}
        |> cast(line, [:debit, :credit])
        |> put_assoc(:account, Map.fetch!(changes, account))
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

  defp update_accounts(multi, lines) when is_list(lines) do
    Enum.reduce(lines, multi, fn line, multi ->
      update_account(multi, line)
    end)
  end

  defp update_account(multi, %{account: account} = line) do
    debit = Map.get(line, :debit, 0)
    credit = Map.get(line, :credit, 0)

    multi
    |> Multi.insert(
      account,
      %AccountModel{
        identifier: to_identifier(account),
        balance_debit: debit,
        balance_credit: credit
      },
      conflict_target: :identifier,
      on_conflict: [inc: [balance_debit: debit, balance_credit: credit]]
    )
  end

  defp to_identifier({type, subtype, id})
       when is_atom(type) and is_binary(subtype) and is_integer(id) do
    [Atom.to_string(type), subtype, Integer.to_string(id)]
  end

  defp to_identifier({type, subtype}) when is_atom(type) and is_binary(subtype) do
    [Atom.to_string(type), subtype]
  end

  defp to_identifier({type, id}) when is_binary(type) and is_integer(id) do
    [type, Integer.to_string(id)]
  end

  defp to_identifier({type, id}) when is_atom(type) and is_integer(id) do
    [Atom.to_string(type), Integer.to_string(id)]
  end

  defp to_identifier(type) when is_binary(type) do
    [type]
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
