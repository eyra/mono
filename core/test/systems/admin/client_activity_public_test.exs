defmodule Systems.Admin.ClientActivityPublicTest do
  use Core.DataCase

  import Systems.Admin.ClientActivityTestHelper

  alias Core.Factories
  alias Systems.Admin
  alias Systems.Project

  @today ~D[2026-10-08]

  defp counts(filters) do
    filters
    |> Admin.Public.list_client_activity(@today)
    |> Map.new(fn %{client: %{id: id}, assignment_count: count} -> {id, count} end)
  end

  describe "client of an assignment" do
    test "is the first owner of the project" do
      first = Factories.insert!(:member)
      second = Factories.insert!(:member)

      insert_project_assignment(
        project_owners: [
          owner(second, ~N[2024-02-01 00:00:00]),
          owner(first, ~N[2024-01-01 00:00:00])
        ]
      )

      assert counts([]) == %{first.id => 1}
    end

    test "assignments whose project has no owner are left out" do
      insert_project_assignment([])

      assert counts([]) == %{}
    end

    test "is the project creator for an assignment created through Projects" do
      creator = Factories.insert!(:member, %{creator: true})
      {:ok, %{project: project}} = Project.Assembly.create("Project", creator, :empty)
      project = Repo.preload(project, :root)

      {:ok, _} = Project.Assembly.create_item(:questionnaire, "Study", project.root, creator)

      assert counts([]) == %{creator.id => 1}
    end

    test "stays the project creator when a co-owner creates the assignment" do
      creator = Factories.insert!(:member, %{creator: true})
      co_owner = Factories.insert!(:member, %{creator: true})
      {:ok, %{project: project}} = Project.Assembly.create("Project", creator, :empty)
      project = Repo.preload(project, :root)

      Repo.update_all(
        from(role in Core.Authorization.RoleAssignment,
          where: role.node_id == ^project.auth_node_id
        ),
        set: [inserted_at: ~N[2024-01-01 00:00:00]]
      )

      {:ok, _} = Project.Public.add_owner!(project, co_owner)
      {:ok, _} = Project.Assembly.create_item(:questionnaire, "Study", project.root, co_owner)

      assert counts([]) == %{creator.id => 1}
    end
  end

  describe "list_client_activity/2" do
    setup do
      client = Factories.insert!(:member)
      other_client = Factories.insert!(:member)

      insert_project_assignment(
        project_owners: [owner(client)],
        status: :concept,
        inserted_at: ~N[2026-03-01 10:00:00]
      )

      insert_project_assignment(
        project_owners: [owner(client)],
        status: :online,
        inserted_at: ~N[2026-04-01 10:00:00]
      )

      insert_project_assignment(
        project_owners: [owner(client)],
        status: :offline,
        inserted_at: ~N[2025-12-31 23:59:59]
      )

      insert_project_assignment(
        project_owners: [owner(other_client)],
        status: :idle,
        inserted_at: ~N[2024-06-01 10:00:00]
      )

      %{client: client, other_client: other_client}
    end

    test "without filters counts all assignments", %{client: client, other_client: other} do
      assert counts([]) == %{client.id => 3, other.id => 1}
    end

    test "this year counts assignments created in the current calendar year", %{client: client} do
      assert counts([:this_year]) == %{client.id => 2}
    end

    test "published counts assignments that are not in concept", %{
      client: client,
      other_client: other
    } do
      assert counts([:published]) == %{client.id => 2, other.id => 1}
    end

    test "this year and published combined", %{client: client} do
      assert counts([:this_year, :published]) == %{client.id => 1}
    end

    test "orders clients by assignment count", %{client: client, other_client: other} do
      assert [%{client: %{id: first}}, %{client: %{id: second}}] =
               Admin.Public.list_client_activity([], @today)

      assert {first, second} == {client.id, other.id}
    end
  end

  describe "list_client_assignments/3" do
    test "lists the client's assignments under the filters, newest first" do
      client = Factories.insert!(:member)
      other = Factories.insert!(:member)

      old =
        insert_project_assignment(
          project_owners: [owner(client)],
          status: :online,
          inserted_at: ~N[2026-01-01 10:00:00]
        )

      new =
        insert_project_assignment(
          project_owners: [owner(client)],
          status: :online,
          inserted_at: ~N[2026-05-01 10:00:00]
        )

      _concept =
        insert_project_assignment(
          project_owners: [owner(client)],
          inserted_at: ~N[2026-06-01 10:00:00]
        )

      _other = insert_project_assignment(project_owners: [owner(other)], status: :online)

      assert [new.id, old.id] ==
               client.id
               |> Admin.Public.list_client_assignments([:published], @today)
               |> Enum.map(fn %{assignment: %{id: id}} -> id end)
    end
  end

  describe "get_client_assignment/1" do
    test "returns the assignment with its client and team" do
      client = Factories.insert!(:member)
      teammate = Factories.insert!(:member)

      %{id: id} =
        insert_project_assignment(
          name: "My study",
          project_owners: [owner(client, ~N[2024-01-01 00:00:00]), owner(teammate)]
        )

      assert %{name: "My study", client: %{id: client_id}, team: team} =
               Admin.Public.get_client_assignment(id)

      assert client_id == client.id
      assert team |> Enum.map(& &1.id) |> Enum.sort() == Enum.sort([client.id, teammate.id])
    end

    test "returns nil for an unknown assignment" do
      assert Admin.Public.get_client_assignment(-1) == nil
    end
  end
end
