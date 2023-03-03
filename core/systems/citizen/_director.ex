defmodule Systems.Citizen.Director do
  defmodule Error do
    @moduledoc false
    defexception [:message]
  end

  @behaviour Systems.Pool.External

  import CoreWeb.Gettext

  alias Systems.{
    Pool,
    Budget,
    Citizen
  }

  @impl true
  def overview_plugin(user) do
    %{
      module: Citizen.Pool.OverviewPlugin,
      props: %{id: :citizen_pools, user: user}
    }
  end

  @impl true
  def submission_plugin(_user), do: nil

  @impl true
  def inclusion_criteria() do
    [:genders]
  end

  @impl true
  def resolve_budget(pool_id, user_id) do
    # return first budget as default or create a new one as a starter
    user = Core.Accounts.get_user!(user_id)
    %{currency: currency} = Pool.Public.get!(pool_id, [:currency])

    case Budget.Public.list_owned_by_currency(user, currency, Budget.Model.preload_graph(:full)) do
      [budget] -> budget
      [budget, _] -> budget
      _ -> create_first_budget(currency, user)
    end
  end

  defp create_first_budget(currency, user) do
    default_name = dgettext("eyra-budget", "budget.default.name")
    Budget.Public.create_budget(currency, default_name, {:emoji, "💰"}, user)
  end
end
