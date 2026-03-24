defmodule Systems.Fund.Assembly do
  @moduledoc """
  Assembly module for creating and managing fund-related entities.
  """
  alias Core.Repo
  alias Systems.Fund
  alias Systems.Content

  @euro_name "euro"
  @euro_type :legal
  @euro_decimal_scale 2

  @doc """
  Gets the euro currency, creating it if it doesn't exist.
  """
  def get_or_create_euro do
    case Fund.Public.get_currency_by_name(@euro_name) do
      %Fund.CurrencyModel{} = currency ->
        currency

      nil ->
        create_euro_currency()
    end
  end

  defp create_euro_currency do
    label_bundle = create_euro_label_bundle()

    %Fund.CurrencyModel{}
    |> Fund.CurrencyModel.change(%{
      name: @euro_name,
      type: @euro_type,
      decimal_scale: @euro_decimal_scale
    })
    |> Ecto.Changeset.put_assoc(:label_bundle, label_bundle)
    |> Repo.insert!()
  end

  defp create_euro_label_bundle do
    %Content.TextBundleModel{
      items: [
        %Content.TextItemModel{locale: "en", text: "\u20AC%{amount}"},
        %Content.TextItemModel{locale: "nl", text: "\u20AC%{amount}"}
      ]
    }
  end
end
