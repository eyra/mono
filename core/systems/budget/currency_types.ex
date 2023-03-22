defmodule Systems.Budget.CurrencyTypes do
  @moduledoc """
  Defines valid types of currencies.
  """
  use Core.Enums.Base, {:currency_types, [:legal, :virtual]}
end
