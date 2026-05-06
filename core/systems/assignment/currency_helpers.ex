defmodule Systems.Assignment.CurrencyHelpers do
  @moduledoc false

  @currency "EUR"

  def format_cents(cents) when is_integer(cents) and cents > 0 do
    cents
    |> cents_to_decimal()
    |> format_currency(locale())
  end

  def format_cents(_), do: format_currency(Decimal.new(0), locale())

  def cents_to_display(nil), do: ""
  def cents_to_display(0), do: ""

  def cents_to_display(cents) when is_integer(cents) do
    cents
    |> cents_to_decimal()
    |> Decimal.to_string(:normal)
  end

  def cents_to_display(value) when is_binary(value) do
    case Integer.parse(value) do
      {cents, _} -> cents_to_display(cents)
      :error -> ""
    end
  end

  def display_to_cents(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, _} ->
        decimal
        |> Decimal.mult(100)
        |> Decimal.round(0)
        |> Decimal.to_integer()

      :error ->
        0
    end
  end

  defp cents_to_decimal(cents) do
    Decimal.div(Decimal.new(cents), Decimal.new(100))
  end

  defp format_currency(%Decimal{} = amount, locale) do
    case CoreWeb.Cldr.Number.to_string(amount,
           format: :currency,
           currency: @currency,
           locale: locale
         ) do
      {:ok, formatted} -> formatted
      _ -> "€0,00"
    end
  end

  defp locale do
    Gettext.get_locale(CoreWeb.Gettext)
  end
end
