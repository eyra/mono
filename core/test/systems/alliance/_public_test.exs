defmodule Systems.Alliance.PublicTest do
  use Core.DataCase

  alias Core.Repo

  alias Systems.{
    Alliance
  }

  describe "alliance_tools" do
    alias Core.Factories

    @update_attrs %{url: "http://eyra.co/fake_alliance"}

    test "list_tools/0 returns all alliance_tools" do
      alliance_tool = Factories.insert!(:alliance_tool)

      assert Alliance.Public.list_tools()
             |> Enum.map(& &1.id)
             |> MapSet.new()
             |> MapSet.member?(alliance_tool.id)
    end

    test "get_tool!/1 returns the alliance_tool with given id" do
      alliance_tool = Factories.insert!(:alliance_tool)

      assert Alliance.Public.get_tool!(alliance_tool.id).id ==
               alliance_tool.id
    end

    test "create_tool/1 with valid data creates a alliance_tool" do
      auth_node = Factories.insert!(:auth_node)

      assert {:ok, %Alliance.ToolModel{} = _alliance_tool} =
               Alliance.Public.prepare_tool(%{}, auth_node) |> Repo.insert()
    end

    test "update_tool/2 with valid data updates the alliance_tool" do
      alliance_tool = Factories.insert!(:alliance_tool)

      assert {:ok, %{tool: alliance_tool}} =
               Alliance.Public.update_tool(
                 alliance_tool,
                 :auto_save,
                 @update_attrs
               )

      assert alliance_tool.url == "http://eyra.co/fake_alliance"
    end

    test "delete_tool/1 deletes the alliance_tool" do
      alliance_tool = Factories.insert!(:alliance_tool)
      assert {:ok, %{}} = Alliance.Public.delete_tool(alliance_tool)

      assert_raise Ecto.NoResultsError, fn ->
        Alliance.Public.get_tool!(alliance_tool.id)
      end
    end

    test "change_tool/1 returns a alliance_tool changeset" do
      alliance_tool = Factories.insert!(:alliance_tool)

      assert %Ecto.Changeset{} = Alliance.Public.change_tool(alliance_tool, :mount)
    end
  end
end
