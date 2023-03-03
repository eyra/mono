defmodule Systems.Org.PublicTest do
  use Core.DataCase

  alias Systems.Org.Public

  describe "organisation" do
    test "create minimal node" do
      assert %{
               type: :university,
               identifier: ["uva"]
             } = Public.create_node!(%{type: :university, identifier: ["uva"]})
    end

    test "create existing node fails" do
      Public.create_node!(%{type: :university, identifier: ["uva"]})

      assert_raise Ecto.InvalidChangesetError, fn ->
        Public.create_node!(%{type: :university, identifier: ["uva"]})
      end

      assert_raise Ecto.InvalidChangesetError, fn ->
        Public.create_node!(%{type: :faculty, identifier: ["uva"]})
      end
    end

    test "link two nodes unidirectional" do
      %{id: node1_id} = node1 = Public.create_node!(%{type: :university, identifier: ["uva"]})
      %{id: node2_id} = node2 = Public.create_node!(%{type: :faculty, identifier: ["sbe"]})

      assert %{
               from: %{id: ^node1_id},
               to: %{id: ^node2_id}
             } = Public.create_link!(node1, node2)

      assert %{
               links: [
                 %{
                   id: ^node2_id
                 }
               ],
               reverse_links: []
             } = Public.get_node!(node1_id, [:links, :reverse_links])

      assert %{
               links: [],
               reverse_links: [
                 %{
                   id: ^node1_id
                 }
               ]
             } = Public.get_node!(node2_id, [:links, :reverse_links])
    end

    test "link two nodes bidirectional" do
      %{id: node1_id} = node1 = Public.create_node!(%{type: :university, identifier: ["uva"]})
      %{id: node2_id} = node2 = Public.create_node!(%{type: :faculty, identifier: ["sbe"]})

      Public.create_link!(node1, node2)
      Public.create_link!(node2, node1)

      assert %{
               links: [
                 %{
                   id: ^node2_id
                 }
               ],
               reverse_links: [
                 %{
                   id: ^node2_id
                 }
               ]
             } = Public.get_node!(node1_id, [:links, :reverse_links])

      assert %{
               links: [
                 %{
                   id: ^node1_id
                 }
               ],
               reverse_links: [
                 %{
                   id: ^node1_id
                 }
               ]
             } = Public.get_node!(node2_id, [:links, :reverse_links])
    end
  end
end
