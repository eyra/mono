defmodule Systems.Pool.SettingsViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Fund
  alias Systems.Pool

  def view_model(%Pool.Model{} = pool, assigns) do
    locale = Map.get(assigns, :locale, :en)
    pool = Core.Repo.preload(pool, currency: Fund.CurrencyModel.preload_graph(:full))

    %{
      changeset: Pool.Model.change(pool, %{}),
      currency_label: Fund.CurrencyModel.title(pool.currency, locale)
    }
  end
end
