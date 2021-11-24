defmodule Systems.Crew.ContextTest do
  use Core.DataCase
  alias Core.Authorization
  alias CoreWeb.UI.Timestamp

  describe "crews" do
    alias Systems.Crew

    test "list/0 returns all created crews with preloaded references" do
      {:ok, crew1} = Crew.Context.create(Core.Authorization.make_node())
      {:ok, crew2} = Crew.Context.create(Core.Authorization.make_node())
      list = Crew.Context.list()
      assert list |> Enum.find(&(&1.id == crew1.id))
      assert list |> Enum.find(&(&1.id == crew2.id))

      assert List.first(list).tasks == []
      assert List.first(list).members == []
    end

    test "get/1 returns crew with preloaded references" do
      {:ok, crew} = Crew.Context.create(Core.Authorization.make_node())
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
      crew = Factories.insert!(:crew)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert member.crew_id == crew.id
      assert member.user_id == user.id
      assert Crew.Context.public_id(crew, user) == 1
    end

    test "get_member/1 returns valid member" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      %{id: id} = Factories.insert!(:crew_member, %{crew: crew, user: user})

      member = Crew.Context.get_member!(id)

      assert member.crew_id == crew.id
      assert member.user_id == user.id
      assert Crew.Context.public_id(crew, user) == 1
    end

    test "member?/2 returns true" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      assert Crew.Context.member?(crew, user) == false
      Factories.insert!(:crew_member, %{crew: crew, user: user})
      assert Crew.Context.member?(crew, user) == true
    end

    test "apply_member/2 creates member + pending task" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: %{id: member_id}, task: task}} = Crew.Context.apply_member(crew, user)

      assert %{
               status: :pending,
               expired: nil,
               started_at: nil,
               completed_at: nil,
               member_id: ^member_id
             } = task
    end

    test "apply_member/2 creates participant role" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member}} = Crew.Context.apply_member(crew, user)

      assert member.crew_id == crew.id
      assert member.user_id == user.id

      assert Crew.Context.public_id(crew, user) == 1

      users = Authorization.users_with_role(crew, :participant)
      assert users |> Enum.find(&(&1.id == user.id))
    end

    test "apply_member/2 reuses expired member" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member1}} = Crew.Context.apply_member(crew, user, expire_at(-1))

      Crew.Context.mark_expired()

      {:ok, %{member: member2}} = Crew.Context.apply_member(crew, user, expire_at(1))

      assert member1.id == member2.id
      assert %{expired: false} = member2
    end

    test "list_members/1 lists only members from that crew" do
      user = Factories.insert!(:member)
      crew1 = Factories.insert!(:crew)
      crew2 = Factories.insert!(:crew)
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

    test "mark_expired/0 does not expire member: expire_at is nil" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member, task: task}} = Crew.Context.apply_member(crew, user, nil)

      assert Crew.Context.mark_expired()

      assert %{expired: false} = Crew.Context.get_member!(member.id)
      assert %{expired: false} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired/0 does not expire member: expire_at is the future" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member, task: task}} = Crew.Context.apply_member(crew, user, expire_at(1))

      assert Crew.Context.mark_expired()

      assert %{expired: false} = Crew.Context.get_member!(member.id)
      assert %{expired: false} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired/0 does not expire member: task started" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member, task: task}} = Crew.Context.apply_member(crew, user, expire_at(-1))
      Crew.Context.start_task(task)

      assert Crew.Context.mark_expired()

      assert %{expired: false} = Crew.Context.get_member!(member.id)
      assert %{expired: false} = Crew.Context.get_task!(task.id)

      assert Crew.Context.member?(crew, user)
    end

    test "mark_expired/0 does expire member: task not started" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member, task: task}} = Crew.Context.apply_member(crew, user, expire_at(-1))

      assert Crew.Context.mark_expired()

      assert %{expired: true} = Crew.Context.get_member!(member.id)
      assert %{expired: true} = Crew.Context.get_task!(task.id)

      assert not Crew.Context.member?(crew, user)
    end

    test "mark_expired/0 does expire member1" do
      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member1, task: task1}} =
        Crew.Context.apply_member(crew, user1, expire_at(-1))

      {:ok, %{member: member2, task: task2}} =
        Crew.Context.apply_member(crew, user2, expire_at(1))

      assert Crew.Context.mark_expired()

      assert %{expired: true} = Crew.Context.get_member!(member1.id)
      assert %{expired: true} = Crew.Context.get_task!(task1.id)
      assert %{expired: false} = Crew.Context.get_member!(member2.id)
      assert %{expired: false} = Crew.Context.get_task!(task2.id)

      assert not Crew.Context.member?(crew, user1)
      assert Crew.Context.member?(crew, user2)
    end

    test "cancel/2 does expire member" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: %{id: member_id} = member, task: task}} =
        Crew.Context.apply_member(crew, user, expire_at(-1))

      assert Crew.Context.member?(crew, user)
      assert [%{id: ^member_id}] = Crew.Context.list_members(crew)

      assert Crew.Context.cancel(crew, user)

      assert %{expired: true} = Crew.Context.get_member!(member.id)
      assert %{expired: true} = Crew.Context.get_task!(task.id)

      assert not Crew.Context.member?(crew, user)
      assert [] = Crew.Context.list_members(crew)
    end
  end

  describe "tasks" do
    alias Systems.Crew
    alias Core.Factories

    test "create_task/2 returns valid task" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      {:ok, task} = Crew.Context.create_task(crew, member, nil)

      assert task.crew_id == crew.id
      assert task.member_id == member.id

      list = Crew.Context.list_members_without_task(crew)
      assert is_nil(list |> Enum.find(&(&1.id == member.id)))
    end

    test "list_tasks/2 returns all available tasks for the crew" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      {:ok, _task} = Crew.Context.create_task(crew, member, nil)

      list = Crew.Context.list_tasks(crew)
      assert list |> Enum.find(&(&1.member_id == member.id))
    end

    test "count_tasks/2 returns correct nr of tasks in the crew" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Context.count_tasks(crew, [:pending, :completed]) == 0

      _task = Factories.insert!(:crew_task, %{crew: crew, member: member, status: :pending})

      assert Crew.Context.count_tasks(crew, [:pending]) == 1
      assert Crew.Context.count_tasks(crew, [:completed]) == 0

      _task = Factories.insert!(:crew_task, %{crew: crew, member: member, status: :completed})
      assert Crew.Context.count_tasks(crew, [:pending]) == 1
      assert Crew.Context.count_tasks(crew, [:completed]) == 1
    end

    test "create_task/2 succeeds for member" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert %{status: :pending, member_id: member_id} =
               Crew.Context.create_task!(crew, member, nil)

      assert member_id == member.id
    end

    test "setup_tasks_for_members/2 " do
      crew = Factories.insert!(:crew)
      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)
      member1 = Factories.insert!(:crew_member, %{crew: crew, user: user1})
      member2 = Factories.insert!(:crew_member, %{crew: crew, user: user2})

      list = Crew.Context.setup_tasks_for_members!([member1, member2], crew)
      assert list |> Enum.find(&(&1.member_id == member1.id))
      assert list |> Enum.find(&(&1.member_id == member2.id))
      assert Crew.Context.count_tasks(crew, [:pending]) == 2
    end

    test "complete_task/1 marks pending task completed" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Context.count_tasks(crew, [:completed]) == 0

      task =
        Factories.insert!(:crew_task, %{
          crew: crew,
          member: member,
          status: :pending
        })

      assert Crew.Context.count_tasks(crew, [:completed]) == 0
      assert %{status: :completed} = Crew.Context.complete_task!(task)
      assert Crew.Context.count_tasks(crew, [:completed]) == 1
    end

    test "complete_task/1 does not mark accepted task completed" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Context.count_tasks(crew, [:completed]) == 0

      task =
        Factories.insert!(:crew_task, %{
          crew: crew,
          member: member,
          status: :pending
        })

      assert Crew.Context.count_tasks(crew, [:completed]) == 0
      {:ok, %{task: task}} = Crew.Context.accept_task(task)
      assert %{status: :accepted} = Crew.Context.complete_task!(task)
      assert Crew.Context.count_tasks(crew, [:completed]) == 0
    end

    test "complete_task/1 does not mark rejected task completed" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Context.count_tasks(crew, [:completed]) == 0

      task =
        Factories.insert!(:crew_task, %{
          crew: crew,
          member: member,
          status: :pending
        })

      assert Crew.Context.count_tasks(crew, [:completed]) == 0

      {:ok, %{task: task}} =
        Crew.Context.reject_task(task, %{
          category: :attention_checks_failed,
          message: "rejection message"
        })

      assert %{status: :rejected} = Crew.Context.complete_task!(task)
      assert Crew.Context.count_tasks(crew, [:completed]) == 0
    end

    test "accept_task/1 marks task accepted" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Context.count_tasks(crew, [:accepted]) == 0

      task =
        Factories.insert!(:crew_task, %{
          crew: crew,
          member: member,
          status: :pending
        })

      assert Crew.Context.count_tasks(crew, [:accepted]) == 0

      assert {:ok,
              %{
                task: %{
                  status: :accepted,
                  accepted_at: accepted_at
                }
              }} = Crew.Context.accept_task(task)

      assert accepted_at != nil
      assert Crew.Context.count_tasks(crew, [:accepted]) == 1
    end

    test "reject_task/1 marks task rejected" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Context.count_tasks(crew, [:rejected]) == 0

      task =
        Factories.insert!(:crew_task, %{
          crew: crew,
          member: member,
          status: :pending
        })

      assert Crew.Context.count_tasks(crew, [:rejected]) == 0

      rejection = %{category: :attention_checks_failed, message: "rejection message"}

      assert {:ok,
              %{
                task: %{
                  status: :rejected,
                  rejected_at: rejected_at,
                  rejected_category: :attention_checks_failed,
                  rejected_message: "rejection message"
                }
              }} = Crew.Context.reject_task(task, rejection)

      assert rejected_at != nil
      assert Crew.Context.count_tasks(crew, [:rejected]) == 1
    end

    test "delete_task/1 " do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Context.count_tasks(crew, [:pending]) == 0

      task =
        Factories.insert!(:crew_task, %{
          crew: crew,
          member: member,
          status: :pending
        })

      assert Crew.Context.count_tasks(crew, [:pending]) == 1

      list = Crew.Context.list_members_without_task(crew)
      assert is_nil(list |> Enum.find(&(&1.id == member.id)))

      Crew.Context.delete_task(task)
      assert Crew.Context.count_tasks(crew, [:pending]) == 0

      list = Crew.Context.list_members_without_task(crew)
      assert list |> Enum.find(&(&1.id == member.id))
    end
  end

  defp expire_at(minutes) do
    Timestamp.naive_from_now(minutes)
  end
end
