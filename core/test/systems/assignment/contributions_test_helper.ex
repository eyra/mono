defmodule Systems.Assignment.ContributionsTestHelper do
  @moduledoc """
  Shared setup for the three sub-view render tests
  (`ContributionsPendingViewTest`, `ContributionsConfirmedViewTest`,
  `ContributionsDeclinedViewTest`). Each test file just needs an
  assignment + a crew member; extracted here to keep the individual test
  files focused on the sub-view being tested.
  """

  alias Core.Factories
  alias Systems.Assignment
  alias Systems.Crew

  @doc """
  Sets up an assignment with a single crew member for the given `user`
  (defaults to a fresh `:member`). Returns a map suitable for
  `{:ok, ...}`ing out of an ExUnit `setup` block.
  """
  def setup_assignment_with_member(user \\ nil) do
    user = user || Factories.insert!(:member)
    %{fund: fund, crew: crew} = assignment = Assignment.Factories.create_assignment(31, 1)
    member = Crew.Factories.create_member(crew, user)

    assignment = Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))
    %{assignment: assignment, fund: fund, user: user, crew: crew, member: member}
  end
end
