defmodule Link.SurveyToolsTest do
  use Link.DataCase

  alias Link.SurveyTools

  describe "survey_tools" do
    alias Link.SurveyTools.SurveyTool
    alias Link.Factories

    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    test "list_survey_tools/0 returns all survey_tools" do
      survey_tool = Factories.insert!(:survey_tool)
      assert SurveyTools.list_survey_tools() |> Enum.map(fn s -> s.id end) == [survey_tool.id]
    end

    test "get_survey_tool!/1 returns the survey_tool with given id" do
      survey_tool = Factories.insert!(:survey_tool)
      assert SurveyTools.get_survey_tool!(survey_tool.id).id == survey_tool.id
    end

    test "create_survey_tool/1 with valid data creates a survey_tool" do
      title = Faker.Lorem.sentence()

      assert {:ok, %SurveyTool{} = survey_tool} =
               SurveyTools.create_survey_tool(
                 %{title: title},
                 Factories.insert!(:study)
               )

      assert survey_tool.title == title
    end

    test "create_survey_tool/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               SurveyTools.create_survey_tool(@invalid_attrs, Factories.insert!(:study))
    end

    test "update_survey_tool/2 with valid data updates the survey_tool" do
      survey_tool = Factories.insert!(:survey_tool)

      assert {:ok, %SurveyTool{} = survey_tool} =
               SurveyTools.update_survey_tool(survey_tool, @update_attrs)

      assert survey_tool.title == "some updated title"
    end

    test "update_survey_tool/2 with invalid data returns error changeset" do
      survey_tool = Factories.insert!(:survey_tool)

      assert {:error, %Ecto.Changeset{}} =
               SurveyTools.update_survey_tool(survey_tool, @invalid_attrs)

      assert survey_tool.id == SurveyTools.get_survey_tool!(survey_tool.id).id
    end

    test "delete_survey_tool/1 deletes the survey_tool" do
      survey_tool = Factories.insert!(:survey_tool)
      assert {:ok, %SurveyTool{}} = SurveyTools.delete_survey_tool(survey_tool)
      assert_raise Ecto.NoResultsError, fn -> SurveyTools.get_survey_tool!(survey_tool.id) end
    end

    test "change_survey_tool/1 returns a survey_tool changeset" do
      survey_tool = Factories.insert!(:survey_tool)
      assert %Ecto.Changeset{} = SurveyTools.change_survey_tool(survey_tool)
    end

    test "get_task/2 returns a task when available" do
      survey_tool_task = Factories.insert!(:survey_tool_task)

      assert SurveyTools.get_task(survey_tool_task.survey_tool, survey_tool_task.user)
             |> Map.take([:user_id, :survey_tool_id]) ==
               survey_tool_task |> Map.take([:user_id, :survey_tool_id])
    end

    test "setup_tasks_for_participants/1 creates task for all entered participants" do
      survey_tool = Factories.insert!(:survey_tool)

      [applied, rejected, entered] =
        [:applied, :rejected, :entered]
        |> Enum.map(&Factories.insert!(:study_participant, study: survey_tool.study, status: &1))

      SurveyTools.setup_tasks_for_participants(survey_tool)

      SurveyTools.list_tasks(survey_tool) |> Enum.map(& &1.user_id) == [entered.user_id]
    end

    test "complete_task/2 marks a survey tool task as completed" do
      task = Factories.insert!(:survey_tool_task)
      survey_tool = task.survey_tool

      SurveyTools.list_tasks(survey_tool) |> Enum.map(& &1.user_id) == [task.user_id]
    end
  end
end
