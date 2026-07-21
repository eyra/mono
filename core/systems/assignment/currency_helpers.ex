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
    decimal = cents_to_decimal(cents)

    case CoreWeb.Cldr.Number.to_string(decimal, locale: locale()) do
      {:ok, formatted} -> formatted
      _ -> Decimal.to_string(decimal, :normal)
    end
  end

  def cents_to_display(value) when is_binary(value) do
    case Integer.parse(value) do
      {cents, _} -> cents_to_display(cents)
      :error -> ""
    end
  end

  # Accepts a plain decimal amount with either `.`, `,`, or `٫` as decimal
  # separator (auto-fix of the wrong locale separator). Rejects anything that
  # looks like a thousands grouping — the field is never asked to include one.
  @amount_regex ~r/^\d+([.,\x{066B}]\d+)?$/u

  def display_to_cents(""), do: {:ok, 0}

  def display_to_cents(value) when is_binary(value) do
    if Regex.match?(@amount_regex, value) do
      value
      |> String.replace(["٫", ","], ".")
      |> parse_decimal_to_cents()
    else
      :error
    end
  end

  defp parse_decimal_to_cents(string) do
    case Decimal.parse(string) do
      {decimal, ""} ->
        cents =
          decimal
          |> Decimal.mult(100)
          |> Decimal.round(0)
          |> Decimal.to_integer()

        {:ok, cents}

      _ ->
        :error
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
