defmodule Systems.Fund.Assembly do
  @moduledoc """
  Assembly module for creating and managing fund-related entities.
  """
  alias Core.Repo
  alias Systems.Fund
  alias Systems.Content

  # Maps a Budget.CurrencyLedgerModel currency enum (:EUR, :USD) to its
  # Fund.CurrencyModel spec.
  #
  # The ledger uses ISO-style atoms (:EUR/:USD) while Fund.CurrencyModel.name
  # is a friendly name ("euro"). These are two different naming domains, so the
  # mapping MUST be explicit here and must never be derived from the atom (e.g.
  # `Atom.to_string |> downcase`), which would look up "eur" and never find the
  # "euro" row.
  @currency_specs %{
    EUR: %{name: "euro", type: :legal, decimal_scale: 2, sign: "€"},
    USD: %{name: "dollar", type: :legal, decimal_scale: 2, sign: "$"}
  }

  @doc """
  Gets the Fund.CurrencyModel for the given currency ledger atom
  (:EUR or :USD), creating it if it doesn't exist.
  """
  def get_or_create(currency) when is_atom(currency) do
    %{name: name} = spec = Map.fetch!(@currency_specs, currency)

    case Fund.Public.get_currency_by_name(name) do
      %Fund.CurrencyModel{} = currency ->
        currency

      nil ->
        create_currency(spec)
    end
  end

  @doc """
  Gets the euro currency, creating it if it doesn't exist.
  """
  def get_or_create_euro, do: get_or_create(:EUR)

  defp create_currency(%{name: name, type: type, decimal_scale: decimal_scale, sign: sign}) do
    label_bundle = create_label_bundle(sign)

    %Fund.CurrencyModel{}
    |> Fund.CurrencyModel.change(%{
      name: name,
      type: type,
      decimal_scale: decimal_scale
    })
    |> Ecto.Changeset.put_assoc(:label_bundle, label_bundle)
    |> Repo.insert!()
  end

  defp create_label_bundle(sign) do
    %Content.TextBundleModel{
      items: [
        %Content.TextItemModel{locale: "en", text: "#{sign}%{amount}"},
        %Content.TextItemModel{locale: "nl", text: "#{sign}%{amount}"}
      ]
    }
  end
end
