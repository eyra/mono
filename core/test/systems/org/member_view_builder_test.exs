defmodule Systems.Org.MemberViewBuilderTest do
  @moduledoc """
  Coverage for FX#9905891585 — search bar + filter chips on the Members
  tab. The builder must filter members by chip (OR semantics across the
  set) and by search query, cap the rendered list at 50, and report the
  uncapped count.
  """
  use Core.DataCase

  alias Core.Factories
  alias Systems.Org

  setup do
    org =
      Factories.insert!(:org_node, %{
        identifier: ["user_view_builder_test_org"],
        domains: ["builder-test.org"]
      })

    current_user = Factories.insert!(:creator)

    %{org: org, assigns: %{current_user: current_user, locale: :en}}
  end

  describe "view_model/2 baseline" do
    test "returns the standard view-model keys", %{org: org, assigns: assigns} do
      vm = Org.MemberViewBuilder.view_model(org, assigns)

      assert is_list(vm.people)
      assert is_list(vm.users)
      assert is_integer(vm.user_count)
      assert is_list(vm.filter_labels)
      assert is_binary(vm.search_placeholder)
      assert vm.query_string == ""
    end

    test "people is empty when the org has no members", %{org: org, assigns: assigns} do
      vm = Org.MemberViewBuilder.view_model(org, assigns)
      assert vm.people == []
      assert vm.user_count == 0
    end
  end

  describe "view_model/2 cap" do
    test "caps the rendered members list at 50 but user_count reflects the full total",
         %{org: org, assigns: assigns} do
      for i <- 1..60 do
        creator = Factories.insert!(:creator, %{email: "cap_user_#{i}@builder-test.org"})
        Org.Public.add_member(org, creator)
      end

      vm = Org.MemberViewBuilder.view_model(org, assigns)

      assert length(vm.people) == 50
      assert vm.user_count == 60
    end
  end

  describe "view_model/2 :external filter" do
    test "narrows to members whose email is outside the org's domains",
         %{org: org, assigns: assigns} do
      internal = Factories.insert!(:creator, %{email: "alice@builder-test.org"})
      external = Factories.insert!(:creator, %{email: "alice@elsewhere.example"})
      Org.Public.add_member(org, internal)
      Org.Public.add_member(org, external)

      vm = Org.MemberViewBuilder.view_model(org, Map.put(assigns, :active_filters, [:external]))

      member_emails = Enum.map(vm.people, & &1.email)
      assert external.email in member_emails
      refute internal.email in member_emails
    end
  end

  describe "view_model/2 :recent filter" do
    test "includes members added this week", %{org: org, assigns: assigns} do
      member = Factories.insert!(:creator, %{email: "recent@builder-test.org"})
      Org.Public.add_member(org, member)

      vm = Org.MemberViewBuilder.view_model(org, Map.put(assigns, :active_filters, [:recent]))

      member_emails = Enum.map(vm.people, & &1.email)
      assert member.email in member_emails
    end

    test "excludes members whose role was granted before the start of this week",
         %{org: org, assigns: assigns} do
      member = Factories.insert!(:creator, %{email: "older@builder-test.org"})
      Org.Public.add_member(org, member)

      backdate_role_assignment!(org, member, ~N[2020-01-01 00:00:00])

      vm = Org.MemberViewBuilder.view_model(org, Map.put(assigns, :active_filters, [:recent]))

      member_emails = Enum.map(vm.people, & &1.email)
      refute member.email in member_emails
    end
  end

  describe "view_model/2 OR semantics across chips" do
    test ":external + :recent returns members matching either chip",
         %{org: org, assigns: assigns} do
      external_old = Factories.insert!(:creator, %{email: "external@elsewhere.example"})
      internal_recent = Factories.insert!(:creator, %{email: "internal@builder-test.org"})
      internal_old = Factories.insert!(:creator, %{email: "old@builder-test.org"})

      Org.Public.add_member(org, external_old)
      Org.Public.add_member(org, internal_recent)
      Org.Public.add_member(org, internal_old)

      backdate_role_assignment!(org, external_old, ~N[2020-01-01 00:00:00])
      backdate_role_assignment!(org, internal_old, ~N[2020-01-01 00:00:00])

      vm =
        Org.MemberViewBuilder.view_model(
          org,
          Map.put(assigns, :active_filters, [:external, :recent])
        )

      member_emails = Enum.map(vm.people, & &1.email)
      assert external_old.email in member_emails
      assert internal_recent.email in member_emails
      refute internal_old.email in member_emails
    end
  end

  describe "view_model/2 search" do
    test "narrows the list by matching the email", %{org: org, assigns: assigns} do
      match = Factories.insert!(:creator, %{email: "needle@builder-test.org"})
      other = Factories.insert!(:creator, %{email: "haystack@builder-test.org"})
      Org.Public.add_member(org, match)
      Org.Public.add_member(org, other)

      vm = Org.MemberViewBuilder.view_model(org, Map.put(assigns, :query, ["needle"]))

      member_emails = Enum.map(vm.people, & &1.email)
      assert match.email in member_emails
      refute other.email in member_emails
    end
  end

  defp backdate_role_assignment!(org, user, %NaiveDateTime{} = at) do
    import Ecto.Query, only: [from: 2]

    {1, _} =
      from(ra in Core.Authorization.RoleAssignment,
        where:
          ra.node_id == ^org.auth_node_id and
            ra.principal_id == ^user.id and
            ra.role == :member
      )
      |> Core.Repo.update_all(set: [inserted_at: at])
  end
end
