defmodule Systems.Org.ContextTest do
  use Core.DataCase

  alias Systems.Org.Context

  describe "organisation" do
    test "create minimal node" do
      assert %{
               type: :university,
               identifier: ["uva"]
             } = Context.create_node!(%{type: :university, identifier: ["uva"]})
    end

    test "create existing node fails" do
      Context.create_node!(%{type: :university, identifier: ["uva"]})

      assert_raise Ecto.InvalidChangesetError, fn ->
        Context.create_node!(%{type: :university, identifier: ["uva"]})
      end

      assert_raise Ecto.InvalidChangesetError, fn ->
        Context.create_node!(%{type: :faculty, identifier: ["uva"]})
      end
    end

    test "link two nodes unidirectional" do
      %{id: node1_id} = node1 = Context.create_node!(%{type: :university, identifier: ["uva"]})
      %{id: node2_id} = node2 = Context.create_node!(%{type: :faculty, identifier: ["sbe"]})

      assert %{
               from: %{id: ^node1_id},
               to: %{id: ^node2_id}
             } = Context.create_link!(node1, node2)

      assert %{
               links: [
                 %{
                   id: ^node2_id
                 }
               ],
               reverse_links: []
             } = Context.get_node!(node1_id, [:links, :reverse_links])

      assert %{
               links: [],
               reverse_links: [
                 %{
                   id: ^node1_id
                 }
               ]
             } = Context.get_node!(node2_id, [:links, :reverse_links])
    end

    test "link two nodes bidirectional" do
      %{id: node1_id} = node1 = Context.create_node!(%{type: :university, identifier: ["uva"]})
      %{id: node2_id} = node2 = Context.create_node!(%{type: :faculty, identifier: ["sbe"]})

      Context.create_link!(node1, node2)
      Context.create_link!(node2, node1)

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
             } = Context.get_node!(node1_id, [:links, :reverse_links])

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
             } = Context.get_node!(node2_id, [:links, :reverse_links])
    end
  end
end
