defmodule Systems.Citizen.Director do
  defmodule Error do
    @moduledoc false
    defexception [:message]
  end

  @behaviour Frameworks.Concept.PoolDirector

  alias CoreWeb.UI.Timestamp

  use Gettext, backend: CoreWeb.Gettext

  alias Systems.{
    Pool,
    Budget,
    Citizen
  }

  @impl true
  def overview_plugin(user) do
    %{
      module: Citizen.Pool.OverviewPlugin,
      params: %{id: :citizen_pools, user: user}
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
    user = Systems.Account.Public.get_user!(user_id)
    %{currency: currency} = Pool.Public.get!(pool_id, [:currency])

    case Budget.Public.list_owned_by_currency(user, currency, Budget.Model.preload_graph(:full)) do
      [budget | _] -> budget
      _ -> create_first_budget(currency, user)
    end
  end

  defp create_first_budget(currency, user) do
    default_name = dgettext("eyra-budget", "budget.default.name")
    Budget.Public.create_budget(currency, default_name, {:emoji, "💰"}, user)
  end

  @impl true
  def submit(submission_id) do
    submission = Pool.Public.get_submission!(submission_id)

    Pool.Public.update(submission, %{
      status: :submitted,
      submitted_at: Timestamp.naive_now()
    })
  end
end
