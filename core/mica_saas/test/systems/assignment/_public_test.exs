defmodule MicaSaas.Systems.Assignment.PublicTest do
  use Mica.DataCase
  import Systems.NextAction.TestHelper

  alias Systems.Assignment

  describe "complete_participation/1" do
    setup {Systems.Assignment.TestHelper, :completable_participation}

    test "creates a PendingContributions next-action for the owner", %{
      assignment: %{id: id},
      participation: participation,
      project_owner: project_owner
    } do
      {:ok, _} = Assignment.Public.complete_participation(participation)

      assert_next_action(
        project_owner,
        "/assignment/#{id}/content?tab=contributions"
      )
    end
  end
end
