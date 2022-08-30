defmodule Systems.Pool.Builders.Wallet do
  import CoreWeb.Gettext

  alias Systems.{
    Pool,
    Budget,
    Bookkeeping
  }

  def view_model(
        %Bookkeeping.AccountModel{
          id: id,
          identifier: ["wallet", currency, _user_id]
        } = account,
        user,
        _url_resolver
      ) do
    title = title(currency)

    target = target(account)

    subtitle =
      case target do
        target when target > 0 ->
          dgettext("eyra-assignment", "student.account.target", target: target)

        _ ->
          ""
      end

    balance = Bookkeeping.AccountModel.balance(account)

    pending_rewards = Budget.Context.pending_rewards(user, currency)

    %{
      id: id,
      title: title,
      subtitle: subtitle,
      target_amount: target,
      earned_amount: balance,
      pending_amount: pending_rewards
    }
  end

  defp title(currency) when is_binary(currency) do
    Budget.Context.get_currency_by_name(currency)
    |> title()
  end

  defp title(%Budget.CurrencyModel{name: name} = currency) do
    case Pool.Context.list_by_currency(currency) do
      [pool] -> Pool.Model.title(pool)
      _ -> name
    end
  end

  defp target(%{identifier: [_ | [pool_name | _]]}) do
    %{target: target} = Pool.Context.get_by_name!(pool_name)
    target
  end

  defp target(_), do: nil
end
