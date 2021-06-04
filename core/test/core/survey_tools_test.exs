defmodule Core.SurveyToolsTest do
  use Core.DataCase

  alias Core.SurveyTools
  alias Core.Authorization

  describe "survey_tools" do
    alias Core.SurveyTools.SurveyTool
    alias Core.Factories

    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    test "list_survey_tools/0 returns all survey_tools" do
      survey_tool = Factories.insert!(:survey_tool)

      assert SurveyTools.list_survey_tools()
             |> Enum.map(& &1.id)
             |> MapSet.new()
             |> MapSet.member?(survey_tool.id)
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

    test "delete_survey_tool/1 deletes the survey tool even with participations attached" do
      survey_tool = Factories.insert!(:survey_tool)
      participant = Factories.insert!(:member)
      SurveyTools.apply_participant(survey_tool, participant)
      assert {:ok, %SurveyTool{}} = SurveyTools.delete_survey_tool(survey_tool)
      assert_raise Ecto.NoResultsError, fn -> SurveyTools.get_survey_tool!(survey_tool.id) end
    end

    test "change_survey_tool/1 returns a survey_tool changeset" do
      survey_tool = Factories.insert!(:survey_tool)
      assert %Ecto.Changeset{} = SurveyTools.change_survey_tool(survey_tool, :mount)
    end

    test "apply_participant/2 creates application" do
      survey_tool = Factories.insert!(:survey_tool)
      member = Factories.insert!(:researcher)
      assert {:ok, _} = SurveyTools.apply_participant(survey_tool, member)
    end

    test "apply_participant/2 notifies the researchers" do
      survey_tool = Factories.insert!(:survey_tool)
      researcher = Factories.insert!(:researcher)
      Authorization.assign_role(researcher, survey_tool, :owner)
      member = Factories.insert!(:researcher)
      {:ok, _} = SurveyTools.apply_participant(survey_tool, member)

      assert Core.NotificationCenter.list(researcher) |> Enum.map(& &1.title) == [
               "New application for: #{survey_tool.title}"
             ]
    end

    test "apply_participant/2 assigns the participant role to the applicant" do
      survey_tool = Factories.insert!(:survey_tool)
      member = Factories.insert!(:researcher)
      assert Authorization.list_roles(member, survey_tool) == MapSet.new()
      assert {:ok, _} = SurveyTools.apply_participant(survey_tool, member)
      assert Authorization.list_roles(member, survey_tool) == MapSet.new([:participant])
    end

    test "list_participants/1 lists all participants" do
      survey = Factories.insert!(:survey_tool)
      _non_particpant = Factories.insert!(:researcher)
      applied_participant = Factories.insert!(:researcher)
      SurveyTools.apply_participant(survey, applied_participant)

      assert SurveyTools.list_participants(survey)
             |> Enum.map(&%{user_id: &1.user.id}) == [
               %{user_id: applied_participant.id}
             ]
    end

    test "list_participations/1 list all studies a user is a part of" do
      survey_tool = Factories.insert!(:survey_tool)
      member = Factories.insert!(:member)
      # Listing without any participation should return an empty list
      assert SurveyTools.list_participations(member) == []
      # The listing should contain the survey tool after an application has been made
      SurveyTools.apply_participant(survey_tool, member)
      assert SurveyTools.list_participations(member) |> Enum.map(& &1.id) == [survey_tool.id]
    end

    test "get_task/2 returns a task when available" do
      survey_tool_task = Factories.insert!(:survey_tool_task)

      assert SurveyTools.get_task(survey_tool_task.survey_tool, survey_tool_task.user)
             |> Map.take([:user_id, :survey_tool_id]) ==
               survey_tool_task |> Map.take([:user_id, :survey_tool_id])
    end

    test "setup_tasks_for_participants/2 creates task for participants" do
      survey_tool = Factories.insert!(:survey_tool)

      participant = Factories.insert!(:survey_tool_participant, %{survey_tool: survey_tool})

      assert SurveyTools.setup_tasks_for_participants!([participant], survey_tool)
             |> Enum.count() == 1

      assert SurveyTools.list_tasks(survey_tool) |> Enum.map(& &1.user_id) == [
               participant.user_id
             ]
    end

    test "list_participants_without_task/2 returns the participants for a study that do not have a survey task" do
      survey_tool = Factories.insert!(:survey_tool)
      assert SurveyTools.list_participants_without_task(survey_tool) == []

      participant_without_task =
        Factories.insert!(:survey_tool_participant, %{survey_tool: survey_tool})

      assert SurveyTools.list_participants_without_task(survey_tool)
             |> Enum.map(& &1.user_id) ==
               [participant_without_task.user_id]

      %SurveyTools.SurveyToolTask{
        user: participant_without_task.user,
        survey_tool: survey_tool,
        status: :pending
      }
      |> Core.Repo.insert!()

      assert SurveyTools.list_participants_without_task(survey_tool) == []
    end

    test "list_tasks/1 returns the tasks for a survery tool" do
      task = Factories.insert!(:survey_tool_task)
      survey_tool = task.survey_tool

      assert SurveyTools.list_tasks(survey_tool) |> Enum.map(& &1.user_id) == [task.user_id]
    end

    test "complete_task/2 marks a survey tool task as completed" do
      task = Factories.insert!(:survey_tool_task)
      survey_tool = task.survey_tool

      assert SurveyTools.complete_task!(task)
      assert SurveyTools.get_task(survey_tool, task.user).status == :completed
    end
  end
end
