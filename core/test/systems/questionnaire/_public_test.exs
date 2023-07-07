defmodule Systems.Questionnaire.PublicTest do
  use Core.DataCase

  alias Systems.{
    Questionnaire
  }

  describe "questionnaire_tools" do
    alias Core.Factories

    @update_attrs %{questionnaire_url: "http://eyra.co/fake_questionnaire"}

    test "list_questionnaire_tools/0 returns all questionnaire_tools" do
      questionnaire_tool = Factories.insert!(:questionnaire_tool)

      assert Questionnaire.Public.list_questionnaire_tools()
             |> Enum.map(& &1.id)
             |> MapSet.new()
             |> MapSet.member?(questionnaire_tool.id)
    end

    test "get_questionnaire_tool!/1 returns the questionnaire_tool with given id" do
      questionnaire_tool = Factories.insert!(:questionnaire_tool)

      assert Questionnaire.Public.get_questionnaire_tool!(questionnaire_tool.id).id ==
               questionnaire_tool.id
    end

    test "create_tool/1 with valid data creates a questionnaire_tool" do
      auth_node = Factories.insert!(:auth_node)

      assert {:ok, %Questionnaire.ToolModel{} = _questionnaire_tool} =
               Questionnaire.Public.create_tool(%{}, auth_node)
    end

    test "update_questionnaire_tool/2 with valid data updates the questionnaire_tool" do
      questionnaire_tool = Factories.insert!(:questionnaire_tool)

      assert {:ok, %{tool: questionnaire_tool}} =
               Questionnaire.Public.update_questionnaire_tool(
                 questionnaire_tool,
                 :auto_save,
                 @update_attrs
               )

      assert questionnaire_tool.questionnaire_url == "http://eyra.co/fake_questionnaire"
    end

    test "delete_questionnaire_tool/1 deletes the questionnaire_tool" do
      questionnaire_tool = Factories.insert!(:questionnaire_tool)
      assert {:ok, %{}} = Questionnaire.Public.delete_questionnaire_tool(questionnaire_tool)

      assert_raise Ecto.NoResultsError, fn ->
        Questionnaire.Public.get_questionnaire_tool!(questionnaire_tool.id)
      end
    end

    test "change_questionnaire_tool/1 returns a questionnaire_tool changeset" do
      questionnaire_tool = Factories.insert!(:questionnaire_tool)

      assert %Ecto.Changeset{} =
               Questionnaire.Public.change_questionnaire_tool(questionnaire_tool, :mount)
    end
  end
end
