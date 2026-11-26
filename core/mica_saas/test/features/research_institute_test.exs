defmodule MicaSaasWeb.Features.ResearchInstituteTest do
  @moduledoc """
  UC-LINK-01: support marks an organisation as a research institute, enters
  its domain, adds the researchers on that domain, and adds a researcher with
  an address outside it by hand. Each member shows who added them.
  """
  use MicaSaasWeb.FeatureCase

  alias Systems.Org

  @tag :feature
  feature "support marks a research institute and adds its researchers", %{session: session} do
    password = Factories.valid_user_password()
    support = Factories.insert!(:member, %{email: "admin1@example.org", password: password})
    on_domain = Factories.insert!(:creator, %{email: "researcher@uni.test"})
    by_hand = Factories.insert!(:creator, %{email: "researcher@gmail.test"})

    org = Factories.insert!(:org_node, %{identifier: ["feature_research_institute"]})

    session
    |> sign_in(support, password)
    |> visit("/org/node/#{org.id}")
    |> assert_connected("[data-testid='org-tab-node']")
    |> click(Query.css("[data-testid='org-tab-node']"))
    |> assert_connected("[data-testid='research-institute-checkbox']")
    |> click(Query.css("[data-testid='research-institute-checkbox']"))
    |> assert_has(Query.css("[data-testid='research-institute-note']"))
    |> fill_in(Query.css("input[name='node_model[domains_string]']"), with: "uni.test")
    |> retry_until(fn -> Org.Public.get_node!(org.id).domains == ["uni.test"] end)
    |> click(Query.css("[data-testid='org-tab-users']"))
    |> assert_has(Query.css("[phx-click='add_all_domain_matched']"))
    |> click(Query.css("[phx-click='add_all_domain_matched']"))
    |> assert_has(Query.text(on_domain.email))
    |> fill_in(Query.css("#members_editor_search_bar_form input[name='query']"),
      with: by_hand.email
    )
    |> assert_has(Query.css("[phx-click='add'][phx-value-item='#{by_hand.id}']"))
    |> click(Query.css("[phx-click='add'][phx-value-item='#{by_hand.id}']"))
    |> assert_has(Query.text(by_hand.email))

    assert Org.NodeModel.research_institute?(Org.Public.get_node!(org.id))

    memberships = Org.Public.list_memberships(org)
    assert Enum.sort(Enum.map(memberships, & &1.user.id)) == Enum.sort([on_domain.id, by_hand.id])
    assert Enum.all?(memberships, &(&1.added_by.id == support.id))
  end

  defp retry_until(session, check, attempts \\ 50) do
    cond do
      check.() -> session
      attempts == 0 -> flunk("condition not met")
      true -> Process.sleep(100) && retry_until(session, check, attempts - 1)
    end
  end
end
