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

  @doc """
  A funded assignment with an owner and a pay-in, and a member's participation
  with a reserved reward: `setup {Systems.Assignment.TestHelper, :completable_participation}`.
  """
  def completable_participation(_context) do
    user = Mica.Factories.insert!(:member)
    %{fund: fund} = assignment = Assignment.Factories.create_assignment(31, 1)

    project_owner = Mica.Factories.insert!(:member)
    :ok = Mica.Authorization.assign_role(project_owner, assignment, :owner)

    assignment = Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))

    idempotence_key = Assignment.Private.reward_idempotence_key(assignment, user)
    {:ok, _} = Fund.Public.create_reward(fund, 1000, user, idempotence_key)
    Fund.Factories.insert_pay_in!(fund, project_owner)
    {:ok, participation} = Assignment.Public.obtain_participation(assignment, user)

    {:ok,
     user: user,
     assignment: assignment,
     participation: participation,
     project_owner: project_owner,
     idempotence_key: idempotence_key}
  end

  @doc """
  A funded assignment with an owner and a member's participation, the context of
  `assignment_participation` signal tests.
  """
  def owned_participation do
    %{fund: fund} = assignment = Assignment.Factories.create_assignment(31, 1)

    owner = Mica.Factories.insert!(:member)
    :ok = Mica.Authorization.assign_role(owner, assignment, :owner)

    participant = Mica.Factories.insert!(:member)

    assignment = Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))
    {:ok, participation} = Assignment.Public.obtain_participation(assignment, participant)

    %{
      assignment: assignment,
      fund: fund,
      owner: owner,
      participant: participant,
      participation: participation
    }
  end
end
