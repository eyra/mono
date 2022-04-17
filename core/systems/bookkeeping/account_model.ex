defmodule Systems.Bookkeeping.AccountModel do
  use Ecto.Schema

  schema "book_accounts" do
    field(:identifier, {:array, :string})
    field(:balance_debit, :integer)
    field(:balance_credit, :integer)
    timestamps()
  end
end

defimpl Frameworks.Utility.ViewModelBuilder, for: Systems.Bookkeeping.AccountModel do
  alias Systems.{
    Bookkeeping
  }

  def view_model(
        %Bookkeeping.AccountModel{
          id: id
        } = account,
        Link.Console,
        _user,
        _url_resolver
      ) do
    title = title(account)

    subtitle =
      case target(account) do
        target when target > 0 -> "#{target} credits needed"
        _ -> ""
      end

    balance = balance(account)
    quick_summary = "Balance: #{balance} credits"

    %{
      id: id,
      path: nil,
      title: title,
      subtitle: subtitle,
      tag: %{type: nil, text: nil},
      level: nil,
      image: nil,
      quick_summary: quick_summary
    }
  end

  defp balance(%{balance_debit: debit, balance_credit: credit}), do: credit - debit

  defp title(%{identifier: [_ | [name | _]]}), do: name

  defp target(%{identifier: [_ | ["sbe_year1_2021" | _]]}), do: 60
  defp target(%{identifier: [_ | ["sbe_year2_2021" | _]]}), do: 3
  defp target(_), do: -1
end
