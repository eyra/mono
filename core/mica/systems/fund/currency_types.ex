defmodule Systems.Fund.CurrencyTypes do
  @moduledoc """
  Defines valid types of currencies.
  """
  use Mica.Enums.Base, {:currency_types, [:legal, :virtual]}
end
