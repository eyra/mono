defmodule Systems.Org.NodeViewBuilderTest do
  use Mica.DataCase

  alias Mica.Factories
  alias Systems.Account
  alias Systems.Org

  setup do
    admin = Factories.insert!(:member, %{email: "admin1@example.org"})
    org = Factories.insert!(:org_node, %{identifier: ["node_view_builder_org"]})
    %{admin: admin, org: org}
  end

  test "an organisation without the mark has no note", %{org: org} do
    vm = Org.NodeViewBuilder.view_model(org, %{is_admin?: true})

    refute vm.research_institute?
    assert vm.research_institute_note == nil
  end

  test "a research institute shows who set the mark", %{admin: admin, org: org} do
    {:ok, org} = Org.Public.mark_research_institute(org, true, admin)

    vm = Org.NodeViewBuilder.view_model(org, %{is_admin?: true})

    assert vm.research_institute?
    assert vm.research_institute_note =~ Account.User.label(admin)
  end

  test "shows when the mark was set in Amsterdam time", %{admin: admin, org: org} do
    {:ok, org} = Org.Public.mark_research_institute(org, true, admin)
    # 23:30 UTC on a winter Thursday is 00:30 on Friday in Amsterdam.
    org = %{org | research_institute_at: ~U[2026-01-15 23:30:00Z]}

    vm = Org.NodeViewBuilder.view_model(org, %{is_admin?: true})

    assert vm.research_institute_note =~ "Friday, January 16"
  end
end
