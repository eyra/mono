defmodule Systems.Crew.PublicTest do
  use Core, :auth
  use Core.DataCase
  alias CoreWeb.UI.Timestamp
  alias Frameworks.GreenLight

  describe "crews" do
    alias Systems.Crew

    test "list/0 returns all created crews with preloaded references" do
      {:ok, crew1} = Crew.Public.prepare(Core.Authorization.prepare_node()) |> Core.Repo.insert()
      {:ok, crew2} = Crew.Public.prepare(Core.Authorization.prepare_node()) |> Core.Repo.insert()
      list = Crew.Public.list()
      assert list |> Enum.find(&(&1.id == crew1.id))
      assert list |> Enum.find(&(&1.id == crew2.id))

      assert List.first(list).tasks == []
      assert List.first(list).members == []
    end

    test "get/1 returns crew with preloaded references" do
      {:ok, crew} = Crew.Public.prepare(Core.Authorization.prepare_node()) |> Core.Repo.insert()
      crew = Crew.Public.get!(crew.id)

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
      assert Crew.Public.public_id(crew, user) == 1
    end

    test "get_member/1 returns valid member" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      %{id: id} = Factories.insert!(:crew_member, %{crew: crew, user: user})

      member = Crew.Public.get_member!(id)

      assert member.crew_id == crew.id
      assert member.user_id == user.id
      assert Crew.Public.public_id(crew, user) == 1
    end

    test "member?/2 returns true" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      assert Crew.Public.member?(crew, user) == false
      Factories.insert!(:crew_member, %{crew: crew, user: user})
      assert Crew.Public.member?(crew, user) == true
    end

    test "apply_member/2 creates member + pending task" do
      %{id: user_id} = user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: %{user_id: ^user_id}, crew_task: task}} =
        Crew.Public.apply_member(crew, user, ["task1"])

      assert %{
               status: :pending,
               expired: false,
               started_at: nil,
               completed_at: nil,
               auth_node: %Core.Authorization.Node{
                 role_assignments: [
                   %Core.Authorization.RoleAssignment{
                     principal_id: ^user_id,
                     role: :owner
                   }
                 ]
               }
             } = task
    end

    test "apply_member/2 creates participant role" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member}} = Crew.Public.apply_member(crew, user, ["task1"])

      assert member.crew_id == crew.id
      assert member.user_id == user.id

      assert Crew.Public.public_id(crew, user) == 1

      users = auth_module().users_with_role(crew, :participant)
      assert users |> Enum.find(&(&1.id == user.id))
    end

    test "apply_member/2 reuses expired member" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member1}} = Crew.Public.apply_member(crew, user, ["task1"], expire_at(-1))

      Crew.Public.mark_expired()

      {:ok, %{member: member2}} = Crew.Public.apply_member(crew, user, ["task1"], expire_at(1))

      assert member1.id == member2.id
      assert %{expired: false} = member2
    end

    test "list_members/1 lists only members from that crew" do
      user = Factories.insert!(:member)

      crew1 = Factories.insert!(:crew)
      crew2 = Factories.insert!(:crew)

      {:ok, %{member: member1}} = Crew.Public.apply_member(crew1, user, ["task1"])
      {:ok, %{member: member2}} = Crew.Public.apply_member(crew2, user, ["task2"])

      list1 = Crew.Public.list_members(crew1)
      list2 = Crew.Public.list_members(crew2)

      assert list1 |> Enum.find(&(&1.id == member1.id))
      assert is_nil(list1 |> Enum.find(&(&1.id == member2.id)))
      assert list2 |> Enum.find(&(&1.id == member2.id))
      assert is_nil(list2 |> Enum.find(&(&1.id == member1.id)))

      assert Crew.Public.public_id(crew1, user) == 1
      assert Crew.Public.public_id(crew2, user) == 1
    end

    test "member_query/0 valid query" do
      assert %{
               aliases: %{member: 0},
               from: %Ecto.Query.FromExpr{
                 source: {"crew_members", Systems.Crew.MemberModel},
                 as: :member
               }
             } = Map.from_struct(Crew.Queries.member_query())
    end

    test "member_query/0 single member" do
      %{id: user_id} = user = Factories.insert!(:member)
      %{id: crew_id} = crew = Factories.insert!(:crew)
      {:ok, %{member: %{id: member_id}}} = Crew.Public.apply_member(crew, user, ["task"])

      assert [
               %Systems.Crew.MemberModel{
                 id: ^member_id,
                 crew_id: ^crew_id,
                 user_id: ^user_id
               }
             ] = Repo.all(Crew.Queries.member_query())
    end

    test "member_query/0 multi member single crew" do
      %{id: user_a_id} = user_a = Factories.insert!(:member)
      %{id: user_b_id} = user_b = Factories.insert!(:member)
      %{id: crew_id} = crew = Factories.insert!(:crew)
      {:ok, %{member: %{id: member_a_id}}} = Crew.Public.apply_member(crew, user_a, ["task_a"])
      {:ok, %{member: %{id: member_b_id}}} = Crew.Public.apply_member(crew, user_b, ["task_b"])

      assert [
               %Systems.Crew.MemberModel{
                 id: ^member_a_id,
                 crew_id: ^crew_id,
                 user_id: ^user_a_id
               },
               %Systems.Crew.MemberModel{
                 id: ^member_b_id,
                 crew_id: ^crew_id,
                 user_id: ^user_b_id
               }
             ] = Repo.all(Crew.Queries.member_query()) |> Enum.sort_by(& &1.id)
    end

    test "member_query/0 multi member multi crew" do
      %{id: user_a_id} = user_a = Factories.insert!(:member)
      %{id: user_b_id} = user_b = Factories.insert!(:member)
      %{id: crew_a_id} = crew_a = Factories.insert!(:crew)
      %{id: crew_b_id} = crew_b = Factories.insert!(:crew)
      {:ok, %{member: %{id: member_a_id}}} = Crew.Public.apply_member(crew_a, user_a, ["task_a"])
      {:ok, %{member: %{id: member_b_id}}} = Crew.Public.apply_member(crew_b, user_b, ["task_b"])

      assert [
               %Systems.Crew.MemberModel{
                 id: ^member_a_id,
                 crew_id: ^crew_a_id,
                 user_id: ^user_a_id
               },
               %Systems.Crew.MemberModel{
                 id: ^member_b_id,
                 crew_id: ^crew_b_id,
                 user_id: ^user_b_id
               }
             ] = Repo.all(Crew.Queries.member_query()) |> Enum.sort_by(& &1.id)
    end

    test "member_query/2 multi member multi crew" do
      %{id: user_a_id} = user_a = Factories.insert!(:member)
      %{id: _user_b_id} = user_b = Factories.insert!(:member)
      %{id: crew_a_id} = crew_a = Factories.insert!(:crew)
      %{id: _crew_b_id} = crew_b = Factories.insert!(:crew)
      {:ok, %{member: %{id: member_a_id}}} = Crew.Public.apply_member(crew_a, user_a, ["task_a"])
      {:ok, %{member: %{id: _member_b_id}}} = Crew.Public.apply_member(crew_b, user_b, ["task_b"])

      assert [
               %Systems.Crew.MemberModel{
                 id: ^member_a_id,
                 crew_id: ^crew_a_id,
                 user_id: ^user_a_id
               }
             ] = Repo.all(Crew.Queries.members_by_task_role_query(crew_a, [:owner]))
    end

    test "mark_expired/0 does not expire member: expire_at is nil" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member, crew_task: task}} =
        Crew.Public.apply_member(crew, user, ["task1"], nil)

      assert Crew.Public.mark_expired()

      assert %{expired: false} = Crew.Public.get_member!(member.id)
      assert %{expired: false} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired/0 does not expire member: expire_at is the future" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member, crew_task: task}} =
        Crew.Public.apply_member(crew, user, ["task1"], expire_at(1))

      assert Crew.Public.mark_expired()

      assert %{expired: false} = Crew.Public.get_member!(member.id)
      assert %{expired: false} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired/0 does not expire member: task started" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member, crew_task: task}} =
        Crew.Public.apply_member(crew, user, ["task1"], expire_at(-1))

      Crew.Public.start_task(task)

      assert Crew.Public.mark_expired()

      assert %{expired: false} = Crew.Public.get_member!(member.id)
      assert %{expired: false} = Crew.Public.get_task!(task.id)

      assert Crew.Public.member?(crew, user)
    end

    test "mark_expired/0 does expire member: task not started" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member, crew_task: task}} =
        Crew.Public.apply_member(crew, user, ["task1"], expire_at(-1))

      assert Crew.Public.mark_expired()

      assert %{expired: true} = Crew.Public.get_member!(member.id)
      assert %{expired: true} = Crew.Public.get_task!(task.id)

      assert not Crew.Public.member?(crew, user)
    end

    test "mark_expired/0 does expire member1" do
      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member1, crew_task: task1}} =
        Crew.Public.apply_member(crew, user1, ["task1"], expire_at(-1))

      {:ok, %{member: member2, crew_task: task2}} =
        Crew.Public.apply_member(crew, user2, ["task2"], expire_at(1))

      assert %{expired: false} = Crew.Public.get_member!(member1.id)
      assert %{expired: false} = Crew.Public.get_task!(task1.id)
      assert %{expired: false} = Crew.Public.get_member!(member2.id)
      assert %{expired: false} = Crew.Public.get_task!(task2.id)

      assert Crew.Public.mark_expired()

      assert %{expired: true} = Crew.Public.get_member!(member1.id)
      assert %{expired: true} = Crew.Public.get_task!(task1.id)
      assert %{expired: false} = Crew.Public.get_member!(member2.id)
      assert %{expired: false} = Crew.Public.get_task!(task2.id)

      assert not Crew.Public.member?(crew, user1)
      assert Crew.Public.member?(crew, user2)
    end

    test "cancel/2 does expire member" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: %{id: member_id} = member, crew_task: task}} =
        Crew.Public.apply_member(crew, user, ["task1"], expire_at(-1))

      assert Crew.Public.member?(crew, user)
      assert [%{id: ^member_id}] = Crew.Public.list_members(crew)

      assert Crew.Public.cancel(crew, user)

      assert %{expired: true} = Crew.Public.get_member!(member.id)
      assert %{expired: true} = Crew.Public.get_task!(task.id)

      assert not Crew.Public.member?(crew, user)
      assert [] = Crew.Public.list_members(crew)
    end

    test "expire_member/2 does expire member and tasks" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)

      {:ok, %{member: member, crew_task: task}} =
        Crew.Public.apply_member(crew, user, ["task1"], expire_at(60))

      assert %{expired: false} = Crew.Public.get_member!(member.id)
      assert %{expired: false} = Crew.Public.get_task!(task.id)

      Ecto.Multi.new()
      |> Crew.Public.expire_member(member)
      |> Core.Repo.commit()

      assert %{expired: true} = Crew.Public.get_member!(member.id)
      assert %{expired: true} = Crew.Public.get_task!(task.id)
    end
  end

  describe "tasks" do
    alias Systems.Crew
    alias Core.Factories

    test "create_task/2 returns valid task" do
      %{id: user_id} = user = Factories.insert!(:member)
      %{id: crew_id} = crew = Factories.insert!(:crew)
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      {:ok, task} = Crew.Public.create_task(crew, user, ["task1"], nil)

      assert %{
               crew_id: ^crew_id,
               auth_node: %Core.Authorization.Node{
                 role_assignments: [
                   %Core.Authorization.RoleAssignment{
                     principal_id: ^user_id,
                     role: :owner
                   }
                 ]
               }
             } = task
    end

    test "list_tasks/1 returns one task for the crew" do
      %{id: crew_id} = crew = Factories.insert!(:crew)

      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)

      _member1 = Factories.insert!(:crew_member, %{crew: crew, user: user1})
      _member2 = Factories.insert!(:crew_member, %{crew: crew, user: user2})

      {:ok, %{auth_node_id: auth_node_id}} =
        Crew.Public.create_task(crew, [user1, user2], ["task1"], nil)

      list = Crew.Public.list_tasks(crew)

      assert [
               %Systems.Crew.TaskModel{
                 identifier: ["task1"],
                 status: :pending,
                 started_at: nil,
                 completed_at: nil,
                 accepted_at: nil,
                 rejected_at: nil,
                 expire_at: nil,
                 expired: false,
                 rejected_category: nil,
                 rejected_message: nil,
                 crew_id: ^crew_id,
                 auth_node_id: ^auth_node_id
               }
             ] = list
    end

    test "list_tasks/1 returns 3 tasks for the crew, latest first" do
      crew = Factories.insert!(:crew)

      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)

      _member1 = Factories.insert!(:crew_member, %{crew: crew, user: user1})
      _member2 = Factories.insert!(:crew_member, %{crew: crew, user: user2})

      {:ok, _} = Crew.Public.create_task(crew, [user1], ["task1"], nil)
      {:ok, _} = Crew.Public.create_task(crew, [user1, user2], ["task2"], nil)
      {:ok, _} = Crew.Public.create_task(crew, [user2], ["task3"], nil)

      list = Crew.Public.list_tasks(crew)

      assert [
               %Systems.Crew.TaskModel{identifier: ["task3"]},
               %Systems.Crew.TaskModel{identifier: ["task2"]},
               %Systems.Crew.TaskModel{identifier: ["task1"]}
             ] = list
    end

    test "list_tasks_for_user/2 returns tasks for one member, latest first" do
      crew = Factories.insert!(:crew)

      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)

      member1 = Factories.insert!(:crew_member, %{crew: crew, user: user1})
      member2 = Factories.insert!(:crew_member, %{crew: crew, user: user2})

      {:ok, _} = Crew.Public.create_task(crew, [user1], ["task1"], nil)
      {:ok, _} = Crew.Public.create_task(crew, [user1, user2], ["task2"], nil)
      {:ok, _} = Crew.Public.create_task(crew, [user2], ["task3"], nil)

      assert [
               %Systems.Crew.TaskModel{identifier: ["task2"]},
               %Systems.Crew.TaskModel{identifier: ["task1"]}
             ] = Crew.Public.list_tasks_for_user(crew, member1)

      assert [
               %Systems.Crew.TaskModel{identifier: ["task3"]},
               %Systems.Crew.TaskModel{identifier: ["task2"]}
             ] = Crew.Public.list_tasks_for_user(crew, member2)
    end

    test "count_tasks/2 returns correct nr of tasks in the crew" do
      user = Factories.insert!(:member)
      auth_node = auth_node_with_owner(user)

      crew = Factories.insert!(:crew)
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Public.count_tasks(crew, [:pending, :completed]) == 0

      _task =
        Factories.insert!(:crew_task, %{
          identifier: ["task1"],
          crew: crew,
          auth_node: auth_node,
          status: :pending
        })

      assert Crew.Public.count_tasks(crew, [:pending]) == 1
      assert Crew.Public.count_tasks(crew, [:completed]) == 0

      _task =
        Factories.insert!(:crew_task, %{
          identifier: ["task2"],
          crew: crew,
          auth_node: auth_node,
          status: :completed
        })

      assert Crew.Public.count_tasks(crew, [:pending]) == 1
      assert Crew.Public.count_tasks(crew, [:completed]) == 1
    end

    test "create_task/2 succeeds for member" do
      %{id: user_id} = user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert %{
               status: :pending,
               auth_node: %{
                 role_assignments: [%{principal_id: ^user_id}]
               }
             } = Crew.Public.create_task!(crew, user, ["task1"], nil)
    end

    test "create_task/2 multiple tasks succeeds for member" do
      %{id: user_id} = user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert %{
               status: :pending,
               auth_node: %{
                 role_assignments: [%{principal_id: ^user_id}]
               }
             } = Crew.Public.create_task!(crew, user, ["task1"], nil)

      assert %{
               status: :pending,
               auth_node: %{
                 role_assignments: [%{principal_id: ^user_id}]
               }
             } = Crew.Public.create_task!(crew, user, ["task2"], nil)

      assert %{
               status: :pending,
               auth_node: %{
                 role_assignments: [%{principal_id: ^user_id}]
               }
             } = Crew.Public.create_task!(crew, user, ["task3"], nil)
    end

    test "create_task/2 multiple tasks succeeds for multiple members" do
      crew = Factories.insert!(:crew)

      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)

      _member1 = Factories.insert!(:crew_member, %{crew: crew, user: user1})
      _member2 = Factories.insert!(:crew_member, %{crew: crew, user: user2})

      assert {:ok, _} = Crew.Public.create_task(crew, user1, ["task1", "member1"], nil)
      assert {:ok, _} = Crew.Public.create_task(crew, user1, ["task2", "member1"], nil)
      assert {:ok, _} = Crew.Public.create_task(crew, user2, ["task1", "member2"], nil)
      assert {:ok, _} = Crew.Public.create_task(crew, user2, ["task2", "member2"], nil)
    end

    test "create_task/2 single task succeeds for team" do
      %{id: crew_id} = crew = Factories.insert!(:crew)

      %{id: user_id1} = user1 = Factories.insert!(:member)
      %{id: user_id2} = user2 = Factories.insert!(:member)

      _member1 = Factories.insert!(:crew_member, %{crew: crew, user: user1})
      _member2 = Factories.insert!(:crew_member, %{crew: crew, user: user2})

      assert %{
               identifier: ["task1"],
               status: :pending,
               crew_id: ^crew_id,
               auth_node: %Core.Authorization.Node{
                 parent_id: nil,
                 role_assignments: [
                   %Core.Authorization.RoleAssignment{
                     principal_id: ^user_id1,
                     role: :owner
                   },
                   %Core.Authorization.RoleAssignment{
                     principal_id: ^user_id2,
                     role: :owner
                   }
                 ]
               }
             } = Crew.Public.create_task!(crew, [user1, user2], ["task1"], nil)
    end

    test "create_task/2 multiple tasks succeeds for multiple teams" do
      %{id: crew_id} = crew = Factories.insert!(:crew)

      %{id: user_id1} = user1 = Factories.insert!(:member)
      %{id: user_id2} = user2 = Factories.insert!(:member)
      %{id: user_id3} = user3 = Factories.insert!(:member)

      _member1 = Factories.insert!(:crew_member, %{crew: crew, user: user1})
      _member2 = Factories.insert!(:crew_member, %{crew: crew, user: user2})
      _member3 = Factories.insert!(:crew_member, %{crew: crew, user: user3})

      assert %{
               identifier: ["task1"],
               status: :pending,
               crew_id: ^crew_id,
               auth_node: %Core.Authorization.Node{
                 parent_id: nil,
                 role_assignments: [
                   %Core.Authorization.RoleAssignment{
                     principal_id: ^user_id1,
                     role: :owner
                   },
                   %Core.Authorization.RoleAssignment{
                     principal_id: ^user_id2,
                     role: :owner
                   }
                 ]
               }
             } = Crew.Public.create_task!(crew, [user1, user2], ["task1"], nil)

      assert %{
               identifier: ["task2"],
               status: :pending,
               crew_id: ^crew_id,
               auth_node: %Core.Authorization.Node{
                 parent_id: nil,
                 role_assignments: [
                   %Core.Authorization.RoleAssignment{
                     principal_id: ^user_id2,
                     role: :owner
                   },
                   %Core.Authorization.RoleAssignment{
                     principal_id: ^user_id3,
                     role: :owner
                   }
                 ]
               }
             } = Crew.Public.create_task!(crew, [user2, user3], ["task2"], nil)
    end

    test "create_task/2 multiple tasks fails for one member: identifier must be unique" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert {:ok, _} = Crew.Public.create_task(crew, user, ["task1"], nil)

      assert {:error,
              %{
                errors: [identifier: {"has already been taken", _}]
              }} = Crew.Public.create_task(crew, user, ["task1"], nil)
    end

    test "create_task/2 multiple tasks fails for multiple members: identifier must be unique" do
      crew = Factories.insert!(:crew)

      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)

      _member1 = Factories.insert!(:crew_member, %{crew: crew, user: user1})
      _member2 = Factories.insert!(:crew_member, %{crew: crew, user: user2})

      assert {:ok, _} = Crew.Public.create_task(crew, user1, ["task1"], nil)

      assert {:error,
              %{
                errors: [identifier: {"has already been taken", _}]
              }} = Crew.Public.create_task(crew, user2, ["task1"], nil)
    end

    test "activate_task/1 marks pending task completed" do
      user = Factories.insert!(:member)
      auth_node = auth_node_with_owner(user)

      crew = Factories.insert!(:crew)
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Public.count_tasks(crew, [:completed]) == 0

      task =
        Factories.insert!(:crew_task, %{
          identifier: ["task1"],
          crew: crew,
          auth_node: auth_node,
          status: :pending
        })

      assert Crew.Public.count_tasks(crew, [:completed]) == 0
      assert %{status: :completed} = Crew.Public.complete_task!(task)
      assert Crew.Public.count_tasks(crew, [:completed]) == 1
    end

    test "activate_task/1 does not mark accepted task completed" do
      user = Factories.insert!(:member)
      auth_node = auth_node_with_owner(user)

      crew = Factories.insert!(:crew)
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Public.count_tasks(crew, [:completed]) == 0

      task =
        Factories.insert!(:crew_task, %{
          identifier: ["task1"],
          crew: crew,
          auth_node: auth_node,
          status: :pending
        })

      assert Crew.Public.count_tasks(crew, [:completed]) == 0
      {:ok, %{crew_task: task}} = Crew.Public.accept_task(task)
      assert %{status: :accepted} = Crew.Public.complete_task!(task)
      assert Crew.Public.count_tasks(crew, [:completed]) == 0
    end

    test "activate_task/1 does not mark rejected task completed" do
      user = Factories.insert!(:member)
      auth_node = auth_node_with_owner(user)

      crew = Factories.insert!(:crew)
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Public.count_tasks(crew, [:completed]) == 0

      task =
        Factories.insert!(:crew_task, %{
          identifier: ["task1"],
          crew: crew,
          auth_node: auth_node,
          status: :pending
        })

      assert Crew.Public.count_tasks(crew, [:completed]) == 0

      {:ok, %{crew_task: task}} =
        Crew.Public.reject_task(task, %{
          category: :attention_checks_failed,
          message: "rejection message"
        })

      assert %{status: :rejected} = Crew.Public.complete_task!(task)
      assert Crew.Public.count_tasks(crew, [:completed]) == 0
    end

    test "accept_task/1 marks task accepted" do
      user = Factories.insert!(:member)
      auth_node = auth_node_with_owner(user)

      crew = Factories.insert!(:crew)
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Public.count_tasks(crew, [:accepted]) == 0

      task =
        Factories.insert!(:crew_task, %{
          identifier: ["task1"],
          crew: crew,
          auth_node: auth_node,
          status: :pending
        })

      assert Crew.Public.count_tasks(crew, [:accepted]) == 0

      assert {:ok,
              %{
                crew_task: %{
                  status: :accepted,
                  accepted_at: accepted_at
                }
              }} = Crew.Public.accept_task(task)

      assert accepted_at != nil
      assert Crew.Public.count_tasks(crew, [:accepted]) == 1
    end

    test "reject_task/1 marks task rejected" do
      user = Factories.insert!(:member)
      auth_node = auth_node_with_owner(user)

      crew = Factories.insert!(:crew)
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Public.count_tasks(crew, [:rejected]) == 0

      task =
        Factories.insert!(:crew_task, %{
          identifier: ["task1"],
          crew: crew,
          auth_node: auth_node,
          status: :pending
        })

      assert Crew.Public.count_tasks(crew, [:rejected]) == 0

      rejection = %{category: :attention_checks_failed, message: "rejection message"}

      assert {:ok,
              %{
                crew_task: %{
                  status: :rejected,
                  rejected_at: rejected_at,
                  rejected_category: :attention_checks_failed,
                  rejected_message: "rejection message"
                }
              }} = Crew.Public.reject_task(task, rejection)

      assert rejected_at != nil
      assert Crew.Public.count_tasks(crew, [:rejected]) == 1
    end

    test "delete_task/1 " do
      user = Factories.insert!(:member)
      auth_node = auth_node_with_owner(user)

      crew = Factories.insert!(:crew)
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      assert Crew.Public.count_tasks(crew, [:pending]) == 0

      task =
        Factories.insert!(:crew_task, %{
          identifier: ["task1"],
          crew: crew,
          auth_node: auth_node,
          status: :pending
        })

      assert Crew.Public.count_tasks(crew, [:pending]) == 1

      Crew.Public.delete_task(task)
      assert Crew.Public.count_tasks(crew, [:pending]) == 0
    end
  end

  defp expire_at(minutes) do
    Timestamp.naive_from_now(minutes)
  end

  defp auth_node_with_owner(user) do
    Factories.insert!(:auth_node, %{
      role_assignments: [
        %{
          role: :owner,
          principal_id: GreenLight.Principal.id(user)
        }
      ]
    })
  end
end
