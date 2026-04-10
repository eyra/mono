defmodule Systems.Assignment.CurrencyHelpers do
  @moduledoc false

  def format_cents(cents) when is_integer(cents) and cents > 0 do
    euros = div(cents, 100)
    remaining = rem(cents, 100)
    "€#{euros},#{String.pad_leading("#{remaining}", 2, "0")}"
  end

  def format_cents(_), do: "€0,00"

  def cents_to_display(nil), do: ""
  def cents_to_display(0), do: ""

  def cents_to_display(cents) when is_integer(cents) do
    euros = div(cents, 100)
    remaining = rem(cents, 100)
    "#{euros}.#{String.pad_leading("#{remaining}", 2, "0")}"
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
end
