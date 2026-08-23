defmodule Systems.Fund.TestHelper do
  @moduledoc """
  Standalone wrappers around `Systems.Fund.Public`'s Multi-composable
  reward operations. Only for tests — production callers must compose
  Fund steps into their own Multi so the reward transition commits
  atomically with whatever state they're changing.

  Each helper loads the reward by key, runs the operation in its own
  transaction, and reloads it — returning `{:ok, %Fund.RewardModel{}}`
  for terse assertions.

  Behaviour when no reward exists for the given key:
    * `mark_pending_approval/1` returns `{:ok, nil}` — matches the
      underlying idempotent no-op semantics.
    * `approve_reward/1` and `reject_reward/1` return
      `{:error, :reward_not_found}` — approving/rejecting a missing
      reward is a caller bug, not an idempotent no-op.
  """
  alias Ecto.Multi
  alias Core.Repo
  alias Systems.Fund

  def mark_pending_approval(idempotence_key) when is_binary(idempotence_key) do
    with_reward(idempotence_key, &Fund.Public.mark_pending_approval/2, on_missing: {:ok, nil})
  end

  def approve_reward(idempotence_key) when is_binary(idempotence_key) do
    with_reward(idempotence_key, &Fund.Public.approve_reward/2)
  end

  def reject_reward(idempotence_key) when is_binary(idempotence_key) do
    with_reward(idempotence_key, &Fund.Public.reject_reward/2)
  end

  defp with_reward(idempotence_key, step, opts \\ []) do
    on_missing = Keyword.get(opts, :on_missing, {:error, :reward_not_found})

    case Fund.Public.get_reward(idempotence_key, Fund.RewardModel.preload_graph(:full)) do
      nil ->
        on_missing

      reward ->
        Multi.new()
        |> step.(reward)
        |> Repo.commit()
        |> case do
          {:ok, _} -> {:ok, Fund.Public.get_reward(idempotence_key, [])}
          {:error, _, reason, _} -> {:error, reason}
        end
    end
  end
end
