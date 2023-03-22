defmodule Systems.Budget.AccountStrategy do
  @behaviour Systems.Bookkeeping.AccountStrategy

  require Logger

  alias Systems.{
    Bookkeeping,
    Budget
  }

  @accounts %{
    fund: "F",
    wallet: "W"
  }
  @account_map Enum.map(@accounts, fn {k, v} -> {v, k} end) |> Enum.into(%{})

  @account_patterns Map.keys(@account_map) |> Enum.join("|")
  @description_re Regex.compile!("(#{@account_patterns})\\s*(\\d+)\\s*\\/\\s*(\\w+)")

  def encode(account) do
    prefix =
      case Bookkeeping.AccountModel.to_identifier(account) do
        ["wallet", _, user_id] -> "#{Map.get(@accounts, :wallet)}#{user_id}"
        ["fund", _] -> "#{Map.get(@accounts, :fund)}"
        _ -> "?"
      end

    "#{prefix}/#{Bookkeeping.AccountModel.checksum(account)}"
  end

  def resolve(currency, :bank) when is_atom(currency) do
    bank_accounts = Budget.Public.list_bank_accounts([:account, :currency])

    case Enum.find(bank_accounts, &(&1.currency.name == to_string(currency))) do
      %{account: %{identifier: identifier}} -> identifier
      nil -> raise "No bank account available for currency `#{currency}`"
    end
  end

  def resolve(currency, description) when is_atom(currency) and is_binary(description) do
    case Regex.run(@description_re, String.upcase(description, :ascii)) do
      [_, type, id, checksum] -> map_to_account(type, currency, id, checksum)
      _ -> :assorted
    end
  end

  defp map_to_account(type, currency, id, checksum)
       when is_binary(type) and is_atom(currency) and is_binary(id) do
    identifier =
      Bookkeeping.Public.to_identifier({
        Map.fetch!(@account_map, type),
        to_string(currency),
        String.to_integer(id)
      })

    if Bookkeeping.Public.valid_checksum?(identifier, checksum) do
      if Bookkeeping.Public.account_exists?(identifier) do
        identifier
      else
        Logger.error("No account found with identifier `#{Enum.join(identifier)}`")
        :unidentified
      end
    else
      Logger.error("Checksum mismatch detected for `#{Enum.join(identifier)}/#{checksum}`")
      :unidentified
    end
  end
end
