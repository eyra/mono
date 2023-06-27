defmodule Systems.Budget.Presenter do
  alias Systems.{
    Budget
  }

  def init_currency_selector(currencies, locale, parent) when is_list(currencies) do
    options = currencies |> Enum.map(&to_option(&1, locale))

    {selected_option_index, selected_currency} =
      if Enum.empty?(options) do
        {nil, nil}
      else
        {0, List.first(currencies)}
      end

    currency_selector = %{
      id: :currency_selector,
      options: options,
      selected_option_index: selected_option_index,
      parent: parent
    }

    {currency_selector, selected_currency}
  end

  defp to_option(%Budget.CurrencyModel{id: id} = currency, locale) do
    %{
      id: id,
      value: Budget.CurrencyModel.title(currency, locale)
    }
  end
end
