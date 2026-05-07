defmodule Systems.Pool.AccountPostActionHandler do
  @moduledoc """
  Handles post account actions intercepted by the Pool switch.
  """

  use Core.FeatureFlags

  require Logger

  alias Systems.Pool
  alias Systems.Account

  def handle(%Account.User{creator: true}, _action), do: :ok

  def handle(%Account.User{} = user, "add_to_panl") do
    if feature_enabled?(:panl) do
      Pool.Public.add_user_to_panl_pool(user)
    else
      Logger.info("Ignoring add_to_panl action: panl feature is disabled")
    end

    :ok
  end

  def handle(%Account.User{id: user_id}, action) do
    Logger.warning(
      "Ignoring unknown post account action: #{inspect(action)} for user: #{user_id}"
    )

    :ok
  end
end
