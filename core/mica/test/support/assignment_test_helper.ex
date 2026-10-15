defmodule Systems.Assignment.TestHelper do
  @moduledoc """
  Test-only wrappers that reach past Assignment.Public to compose
  primitives owned by other systems (Fund). Keeps the reward
  idempotence-key format internal to Assignment.
  """
  alias Systems.Account.User
  alias Systems.Assignment
  alias Systems.Fund

  @doc """
  Creates a Fund reward for the given (assignment, user) pair, in the
  assignment's own fund. Mirrors what `Assignment.Public.add_participant!`
  does at signup time but scoped for tests that need to set up rewards
  directly.
  """
  def create_reward(
        %Assignment.Model{fund: %Fund.Model{} = fund} = assignment,
        %User{} = user,
        amount
      )
      when is_integer(amount) do
    Fund.Public.create_reward(
      fund,
      amount,
      user,
      Assignment.Private.reward_idempotence_key(assignment, user)
    )
  end
end
