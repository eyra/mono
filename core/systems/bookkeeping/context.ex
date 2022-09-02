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

  def get_account!([_ | _] = identifier, preload \\ []) do
    from(account in AccountModel,
      where: account.identifier == ^identifier,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_entry(idempotence_key, preload \\ [:lines]) do
    from(entry in EntryModel,
      where: entry.idempotence_key == ^idempotence_key,
      preload: ^preload
    )
    |> Repo.one()
  end

  def enter(%Multi{} = multi, %{} = entry) do
    update_records(multi, entry)
  end

  def enter(%{lines: lines} = entry) when is_list(lines) do
    result =
      Multi.new()
      |> update_records(entry)
      |> Repo.transaction()

    case result do
      {:ok, any} -> {:ok, any}
      {:error, any} -> {:error, any}
      {:error, :validate, error, _} -> handle_validation_error(error)
      {:error, :entry, changeset, _} -> handle_validation_error(changeset)
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

  def list_accounts(account_template) do
    from(account in AccountModel,
      where: fragment("?::text[] @> ?", account.identifier, ^account_template)
    )
    |> Repo.all()
  end

  def create_account!(account) do
    %AccountModel{
      identifier: to_identifier(account),
      balance_debit: 0,
      balance_credit: 0
    }
    |> Repo.insert!()
  end

  defp update_records(multi, %{lines: lines} = entry) do
    multi
    |> validate(lines)
    |> update_accounts(lines)
    |> insert_entry(entry)
    |> insert_lines(lines)
  end

  defp validate(multi, lines) when is_list(lines) do
    multi
    |> Multi.run(:validate, fn _, _ ->
      with :ok <- validate_entry_balance(lines),
           :ok <- validate_either_credit_or_debit_is_used(lines) do
        {:ok, true}
      else
        error -> error
      end
    end)
  end

  defp insert_line(multi, %{account: account} = line) do
    line_name = "line-#{to_identifier(account) |> Enum.join("-")}"

    multi
    |> Multi.run(line_name, fn repo, %{entry: entry} = changes ->
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

  defp handle_validation_error(%{errors: [idempotence_key: _]}),
    do: {:error, :idempotence_key_conflict}

  defp handle_validation_error(error) when is_atom(error), do: {:error, error}
  defp handle_validation_error(_), do: {:error, :unexpected_entity_error}

  defp update_accounts(multi, lines) when is_list(lines) do
    Enum.reduce(lines, multi, fn line, multi ->
      update_account(multi, line)
    end)
  end

  defp update_account(multi, %{account: account} = line) do
    debit = debit(line)
    credit = credit(line)

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

  def to_identifier(%AccountModel{identifier: identifier}), do: identifier

  def to_identifier({type, subtype, id}) when is_binary(subtype) and is_integer(id) do
    to_identifier([type, subtype, id])
  end

  def to_identifier({type, subtype}) when is_binary(subtype) do
    to_identifier([type, subtype])
  end

  def to_identifier({type, id}) when is_integer(id) do
    to_identifier([type, id])
  end

  def to_identifier(type) when is_atom(type) do
    to_identifier([type])
  end

  def to_identifier(term) when is_list(term), do: Enum.map(term, &to_string(&1))

  defp validate_entry_balance(lines) when is_list(lines) do
    {debit, credit} =
      Enum.reduce(lines, {0, 0}, fn entry, {debit, credit} ->
        {debit + debit(entry), credit + credit(entry)}
      end)

    if debit == credit do
      :ok
    else
      {:error, :unbalanced_lines}
    end
  end

  defp validate_either_credit_or_debit_is_used(lines) when is_list(lines) do
    if Enum.any?(lines, &(debit(&1) > 0 && credit(&1) > 0)) do
      {:error, :entry_with_both_debit_and_credit}
    else
      :ok
    end
  end

  defp debit(%{debit: debit}) when not is_nil(debit), do: debit
  defp debit(_), do: 0
  defp credit(%{credit: credit}) when not is_nil(credit), do: credit
  defp credit(_), do: 0
end
