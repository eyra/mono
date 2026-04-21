defmodule Systems.Fund.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Fund

  def currency_query() do
    from(Fund.CurrencyModel, as: :currency)
  end

  def currency_query(type) do
    build(currency_query(), :currency, [
      type == ^type
    ])
  end
end
