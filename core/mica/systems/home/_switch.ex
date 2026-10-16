defmodule Systems.Home.Switch do
  @moduledoc """
  Routes Fund-side signals to Home page observers so the participant's
  home (rewards summary card in particular) re-renders without a page
  reload after webhook-driven state changes.
  """
  use Frameworks.Signal.Handler

  alias Systems.Home
  alias Systems.Observatory

  @impl true
  def intercept({:fund_rewards_summary, _}, %{user_id: user_id}) do
    refresh_home_for(user_id)
    :ok
  end

  # NextAction changes affect the NBA card on Home. Fires for both :created
  # and :cleared so the card appears/disappears live without a page reload.
  @impl true
  def intercept({:next_action, _}, %{user: %{id: user_id}}) do
    refresh_home_for(user_id)
    :ok
  end

  defp refresh_home_for(user_id) do
    model = Observatory.SingletonModel.instance()
    Observatory.Public.dispatch(Home.Page, [model.id, user_id], %{model: model})
  end
end
