defmodule Systems.Assignment.PrivateTest do
  use Core.DataCase

  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Workflow

  alias Core.Factories

  describe "Crew Task & Workflow Item mapping" do
    test "task_identifier/2" do
      %{crew: crew, workflow: workflow} =
        assignment = Assignment.Factories.create_assignment(31, 1)

      %{items: [%{id: item_id} = item]} = workflow |> Core.Repo.preload([:items])
      user = Factories.insert!(:member)
      member = %{id: member_id} = Crew.Factories.create_member(crew, user)

      assert Assignment.Private.task_identifier(assignment, item, member) == [
               "item=#{item_id}",
               "member=#{member_id}"
             ]
    end

    test "get_workflow_item/2" do
      %{crew: crew, workflow: workflow} = Assignment.Factories.create_assignment(31, 1)
      %{items: [%{id: item_id}]} = workflow |> Core.Repo.preload([:items])

      user = Factories.insert!(:member)
      member = %{id: member_id} = Crew.Factories.create_member(crew, user)

      task =
        Crew.Factories.create_task(crew, member, ["item=#{item_id}", "member=#{member_id}"],
          expired: false
        )

      assert {:ok,
              %Workflow.ItemModel{
                id: ^item_id
              }} = Assignment.Private.get_workflow_item(task, [])
    end

    test "get_crew_member/2" do
      %{crew: crew, workflow: workflow} = Assignment.Factories.create_assignment(31, 1)
      %{items: [%{id: item_id}]} = workflow |> Core.Repo.preload([:items])

      user = %{id: user_id} = Factories.insert!(:member)
      member = %{id: member_id} = Crew.Factories.create_member(crew, user)

      task =
        Crew.Factories.create_task(crew, member, ["item=#{item_id}", "member=#{member_id}"],
          expired: false
        )

      assert {:ok,
              %Crew.MemberModel{
                id: ^member_id,
                user_id: ^user_id
              }} = Assignment.Private.get_crew_member(task, [])
    end
  end
end
