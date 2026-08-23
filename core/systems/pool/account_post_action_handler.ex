defmodule Systems.Pool.AccountPostActionHandler do
  @moduledoc """
  Handles post account actions intercepted by the Pool switch.
  """

  use Core.FeatureFlags

  require Logger

  alias Systems.Pool
  alias Systems.Account

  def handle(%Account.User{creator: true}, _action), do: :ok

  # Legacy value from the pre-OTP signup flow; treat as a Panl-scoped join.
  def handle(%Account.User{} = user, "add_to_panl") do
    handle(user, "join_pool:panl")
  end

  def handle(%Account.User{} = user, "join_pool:" <> slug) do
    with {:ok, slug_atom} <- safe_to_existing_atom(slug),
         %Pool.Model{} = pool <- Pool.Public.get_by_slug(slug_atom) do
      if pool.name == "Panl" and not feature_enabled?(:panl) do
        Logger.info("Ignoring join_pool:#{slug} action: panl feature is disabled")
      else
        Pool.Public.add_participant!(pool, user)
      end
    else
      _ ->
        Logger.warning("Ignoring join_pool:#{slug} action: unknown pool slug")
    end

    :ok
  end

  def handle(%Account.User{id: user_id}, action) do
    Logger.warning(
      "Ignoring unknown post account action: #{inspect(action)} for user: #{user_id}"
    )

    :ok
  end

  defp safe_to_existing_atom(str) when is_binary(str) do
    {:ok, String.to_existing_atom(str)}
  rescue
    ArgumentError -> :error
  end
end
