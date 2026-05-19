defmodule Systems.Fund.Assembly do
  @moduledoc """
  Assembly module for creating and managing fund-related entities.
  """
  alias Core.Repo
  alias Systems.Fund
  alias Systems.Content

  # Ledger enum (:EUR) and currency name ("euro") are different naming domains;
  # the mapping must be explicit, never derived by downcasing the atom.
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
