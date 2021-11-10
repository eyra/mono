defmodule Core.Survey.ToolsTest do
  use Core.DataCase

  alias Core.Survey.Tools

  describe "survey_tools" do
    alias Core.Survey.Tool
    alias Core.Factories

    @update_attrs %{survey_url: "http://eyra.co/fake_survey"}

    test "list_survey_tools/0 returns all survey_tools" do
      survey_tool = Factories.insert!(:survey_tool)

      assert Tools.list_survey_tools()
             |> Enum.map(& &1.id)
             |> MapSet.new()
             |> MapSet.member?(survey_tool.id)
    end

    test "get_survey_tool!/1 returns the survey_tool with given id" do
      survey_tool = Factories.insert!(:survey_tool)
      assert Tools.get_survey_tool!(survey_tool.id).id == survey_tool.id
    end

    test "create_survey_tool/1 with valid data creates a survey_tool" do
      auth_node = Factories.insert!(:auth_node)
      content_node = Factories.insert!(:content_node)

      assert {:ok, %Tool{} = _survey_tool} =
               Tools.create_survey_tool(%{}, auth_node, content_node)
    end

    test "update_survey_tool/2 with valid data updates the survey_tool" do
      survey_tool = Factories.insert!(:survey_tool)

      assert {:ok, %{tool: survey_tool}} =
               Tools.update_survey_tool(survey_tool, :auto_save, @update_attrs)

      assert survey_tool.survey_url == "http://eyra.co/fake_survey"
    end

    test "delete_survey_tool/1 deletes the survey_tool" do
      survey_tool = Factories.insert!(:survey_tool)
      assert {:ok, %{}} = Tools.delete_survey_tool(survey_tool)
      assert_raise Ecto.NoResultsError, fn -> Tools.get_survey_tool!(survey_tool.id) end
    end

    test "change_survey_tool/1 returns a survey_tool changeset" do
      survey_tool = Factories.insert!(:survey_tool)
      assert %Ecto.Changeset{} = Tools.change_survey_tool(survey_tool, :mount)
    end
  end
end
