defmodule Systems.Pool.AccountPostActionHandler do
  @moduledoc """
  Handles post account actions intercepted by the Pool switch.
  """

  require Logger

  alias Systems.Pool
  alias Systems.Account

  @allowed_post_actions ~w(add_to_panl)

  def handle(%Account.User{creator: true}, _action), do: :ok

  def handle(%Account.User{} = user, action) when action in @allowed_post_actions do
    case action do
      "add_to_panl" ->
        # Add participant to PANL pool when available; ignore if not configured
        case Pool.Public.add_user_to_panl_pool(user) do
          :ok -> :ok
          _ -> :ok
        end
    end
  end

  def handle(%Account.User{id: user_id}, action) do
    Logger.warning(
      "Ignoring unknown post account action: #{inspect(action)} for user: #{user_id}"
    )

    :ok
  end
end
