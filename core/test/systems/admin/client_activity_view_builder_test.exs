defmodule Systems.Admin.ClientActivityViewBuilderTest do
  use Core.DataCase

  import Systems.Admin.ClientActivityTestHelper

  alias Core.Factories
  alias Systems.Admin.ClientActivityViewBuilder

  @today ~D[2026-10-08]

  setup do
    client = Factories.insert!(:member)
    teammate = Factories.insert!(:member)

    published =
      insert_project_assignment(
        name: "Published study",
        fund_owners: [owner(client)],
        project_owners: [owner(client), owner(teammate)],
        status: :online,
        inserted_at: ~N[2026-02-01 10:00:00]
      )

    concept =
      insert_project_assignment(
        name: "Concept study",
        fund_owners: [owner(client)],
        inserted_at: ~N[2025-02-01 10:00:00]
      )

    %{client: client, teammate: teammate, published: published, concept: concept}
  end

  defp view_model(assigns) do
    assigns =
      assigns
      |> Map.put_new(:today, @today)
      |> Map.put_new(:is_admin?, true)

    ClientActivityViewBuilder.view_model(nil, assigns)
  end

  describe "without system admin rights" do
    test "builds no client data" do
      assert %{level: %{type: :forbidden}, filter_labels: []} = view_model(%{is_admin?: false})
    end
  end

  describe "clients level" do
    test "lists clients with their assignment count", %{client: %{id: client_id}} do
      assert %{
               title_count: 1,
               filter_labels: filter_labels,
               level: %{type: :clients, clients: [%{id: ^client_id, assignment_count: 2}]}
             } = view_model(%{})

      assert Enum.map(filter_labels, & &1.id) == [:this_year, :published]
    end

    test "published filter", %{client: %{id: client_id}} do
      assert %{level: %{clients: [%{id: ^client_id, assignment_count: 1}]}} =
               view_model(%{active_filters: [:published]})
    end

    test "this year filter", %{client: %{id: client_id}} do
      assert %{level: %{clients: [%{id: ^client_id, assignment_count: 1}]}} =
               view_model(%{active_filters: [:this_year]})

      assert %{level: %{clients: []}} =
               view_model(%{active_filters: [:this_year], today: ~D[2024-05-01]})
    end

    test "both filters combined", %{client: %{id: client_id}} do
      assert %{level: %{clients: [%{id: ^client_id, assignment_count: 1}]}} =
               view_model(%{active_filters: [:this_year, :published]})

      assert %{level: %{clients: []}} =
               view_model(%{active_filters: [:this_year, :published], today: ~D[2025-05-01]})
    end
  end

  describe "client level" do
    test "lists the client's assignments under the filters", %{
      client: %{id: client_id},
      published: %{id: published_id}
    } do
      assert %{
               title_count: nil,
               level: %{
                 type: :client,
                 client: %{id: ^client_id},
                 assignments: [
                   %{id: ^published_id, name: "Published study", created: "2026-02-01"}
                 ]
               }
             } = view_model(%{client_id: client_id, active_filters: [:published]})
    end

    test "falls back to the clients level for an unknown client" do
      assert %{level: %{type: :clients}} = view_model(%{client_id: -1})
    end
  end

  describe "assignment level" do
    test "shows details and team", %{
      client: %{id: client_id} = client,
      teammate: %{id: teammate_id},
      published: %{id: published_id}
    } do
      assert %{level: %{type: :assignment, name: "Published study", details: details, team: team}} =
               view_model(%{client_id: client_id, assignment_id: published_id})

      assert Enum.any?(details, &(&1.value == "#{client.displayname} (#{client.email})"))

      assert team |> Enum.map(&{&1.id, &1.client?}) |> Enum.sort() ==
               Enum.sort([{client_id, true}, {teammate_id, false}])
    end

    test "falls back to the client level for an unknown assignment", %{client: %{id: client_id}} do
      assert %{level: %{type: :client}} = view_model(%{client_id: client_id, assignment_id: -1})
    end
  end
end
