defmodule Systems.Budget.WalletViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

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
        user
      ) do
    locale = Gettext.get_locale(CoreWeb.Gettext)
    currency = Budget.Public.get_currency_by_name(currency, label_bundle: [:items])
    title = Budget.CurrencyModel.title(currency, locale)

    target_amount = target(account)

    subtitle =
      case target_amount do
        target when not is_nil(target) and target > 0 ->
          dgettext("eyra-assignment", "pool.target", target: target_amount)

        _ ->
          ""
      end

    earned_amount = Bookkeeping.AccountModel.balance(account)
    pending_amount = Budget.Public.pending_rewards(user, currency)

    togo_amount =
      if target_amount do
        target_amount - (earned_amount + pending_amount)
      else
        0
      end

    earned_label =
      dgettext("eyra-assignment", "earned.label",
        amount: Budget.CurrencyModel.label(currency, locale, earned_amount)
      )

    pending_label =
      dgettext("eyra-assignment", "pending.label",
        amount: Budget.CurrencyModel.label(currency, locale, pending_amount)
      )

    togo_label =
      dgettext("eyra-assignment", "togo.label",
        amount: Budget.CurrencyModel.label(currency, locale, togo_amount)
      )

    %{
      id: id,
      title: title,
      subtitle: subtitle,
      target_amount: target_amount,
      earned_amount: earned_amount,
      earned_label: earned_label,
      pending_amount: pending_amount,
      pending_label: pending_label,
      togo_amount: togo_amount,
      togo_label: togo_label
    }
  end

  defp target(%{identifier: [_ | [pool_name | _]]}),
    do: target(Pool.Public.get_by_name(pool_name))

  defp target(%{target: target} = _pool), do: target
  defp target(_), do: nil
end
