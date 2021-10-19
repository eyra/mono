defmodule Systems.Crew.ContextTest do
  use Core.DataCase

  alias Core.Authorization

  describe "crews" do
    alias Systems.Crew

    test "list/0 returns all created crews with preloaded references" do
      {:ok, crew1} = Crew.Context.create(:campaign, 1, Core.Authorization.make_node())
      {:ok, crew2} = Crew.Context.create(:campaign, 2, Core.Authorization.make_node())
      list = Crew.Context.list()
      assert list |> Enum.find(&(&1.id == crew1.id))
      assert list |> Enum.find(&(&1.id == crew2.id))

      assert List.first(list).tasks == []
      assert List.first(list).members == []
    end

    test "get/1 returns crew with preloaded references" do
      {:ok, crew} = Crew.Context.create(:campaign, 1, Core.Authorization.make_node())
      crew = Crew.Context.get!(crew.id)

      assert crew.tasks == []
      assert crew.members == []
    end
  end

  describe "members" do
    alias Systems.Crew
    alias Core.Factories

    test "create_member/2 returns valid member" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert member.crew_id == crew.id
      assert member.user_id == user.id
      assert Crew.Context.public_id(crew, user) == 1
    end

    test "get_member/1 returns valid member" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})
      %{id: id} = Factories.insert!(:crew_member, %{crew: crew, user: user})

      member = Crew.Context.get_member!(id)

      assert member.crew_id == crew.id
      assert member.user_id == user.id
      assert Crew.Context.public_id(crew, user) == 1
    end

    test "member?/2 returns true" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})

      assert Crew.Context.member?(crew, user) == false
      Factories.insert!(:crew_member, %{crew: crew, user: user})
      assert Crew.Context.member?(crew, user) == true
    end

    test "apply_member/2 creates particpant role" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})

      {:ok, %{member: member}} = Crew.Context.apply_member(crew, user)

      assert member.crew_id == crew.id
      assert member.user_id == user.id

      assert Crew.Context.public_id(crew, user) == 1

      users = Authorization.users_with_role(crew, :participant)
      assert users |> Enum.find(&(&1.id == user.id))
    end

    test "withdraw_member/2 removes user from crew as memeber and deletes all tasks" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})

      {:ok, _} = Crew.Context.apply_member(crew, user)

      Crew.Context.withdraw_member(crew, user)
      assert Crew.Context.member?(crew, user) == false

      users = Authorization.users_with_role(crew, :participant)
      assert is_nil(users |> Enum.find(&(&1.id == user.id)))
    end

    test "list_members_without_task/1 lists freshly applied member" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})
      {:ok, %{member: member}} = Crew.Context.apply_member(crew, user)

      list = Crew.Context.list_members_without_task(crew)
      assert list |> Enum.find(&(&1.id == member.id))
    end

    test "list_members/1 lists only members from that crew" do
      user = Factories.insert!(:member)
      crew1 = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})
      crew2 = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 2})
      {:ok, %{member: member1}} = Crew.Context.apply_member(crew1, user)
      {:ok, %{member: member2}} = Crew.Context.apply_member(crew2, user)

      list1 = Crew.Context.list_members(crew1)
      list2 = Crew.Context.list_members(crew2)

      assert list1 |> Enum.find(&(&1.id == member1.id))
      assert is_nil(list1 |> Enum.find(&(&1.id == member2.id)))
      assert list2 |> Enum.find(&(&1.id == member2.id))
      assert is_nil(list2 |> Enum.find(&(&1.id == member1.id)))

      assert Crew.Context.public_id(crew1, user) == 1
      assert Crew.Context.public_id(crew2, user) == 1
    end
  end

  describe "tasks" do
    alias Systems.Crew
    alias Core.Factories

    test "create_task/2 returns valid task" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      {:ok, task} = Crew.Context.create_task(crew, member)

      assert task.crew_id == crew.id
      assert task.member_id == member.id

      list = Crew.Context.list_members_without_task(crew)
      assert is_nil(list |> Enum.find(&(&1.id == member.id)))
    end

    test "list_tasks/2 returns creates task" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      {:ok, _task} = Crew.Context.create_task(crew, member)

      list = Crew.Context.list_tasks(crew)
      assert list |> Enum.find(&(&1.member_id == member.id))
    end

    test "count_tasks/2 returns creates task" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Context.count_tasks(crew, [:pending, :completed]) == 0

      _task = Factories.insert!(:crew_task, %{crew: crew, member: member, status: :pending})

      assert Crew.Context.count_tasks(crew, [:pending]) == 1
      assert Crew.Context.count_tasks(crew, [:completed]) == 0

      _task = Factories.insert!(:crew_task, %{crew: crew, member: member, status: :completed})
      assert Crew.Context.count_tasks(crew, [:pending]) == 1
      assert Crew.Context.count_tasks(crew, [:completed]) == 1
    end

    test "get_or_create_task/2 succeeds for member" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      {:ok, _} = Crew.Context.get_or_create_task(crew, member)
    end

    test "setup_tasks_for_members/2 " do
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})
      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)
      member1 = Factories.insert!(:crew_member, %{crew: crew, user: user1})
      member2 = Factories.insert!(:crew_member, %{crew: crew, user: user2})

      list = Crew.Context.setup_tasks_for_members!([member1, member2], crew)
      assert list |> Enum.find(&(&1.member_id == member1.id))
      assert list |> Enum.find(&(&1.member_id == member2.id))
      assert Crew.Context.count_tasks(crew, [:pending]) == 2
    end

    test "complete_task/1 " do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Context.count_tasks(crew, [:completed]) == 0
      task = Factories.insert!(:crew_task, %{crew: crew, member: member, status: :pending})
      assert Crew.Context.count_tasks(crew, [:completed]) == 0
      task = Crew.Context.complete_task!(task)
      assert task.status == :completed
      assert Crew.Context.count_tasks(crew, [:completed]) == 1
    end

    test "delete_task/1 " do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: :campaign, reference_id: 1})
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Context.count_tasks(crew, [:pending]) == 0
      task = Factories.insert!(:crew_task, %{crew: crew, member: member, status: :pending})
      assert Crew.Context.count_tasks(crew, [:pending]) == 1

      list = Crew.Context.list_members_without_task(crew)
      assert is_nil(list |> Enum.find(&(&1.id == member.id)))

      Crew.Context.delete_task(task)
      assert Crew.Context.count_tasks(crew, [:pending]) == 0

      list = Crew.Context.list_members_without_task(crew)
      assert list |> Enum.find(&(&1.id == member.id))
    end
  end
end
