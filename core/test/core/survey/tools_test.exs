defmodule Core.Survey.ToolsTest do
  use Core.DataCase

  alias Core.Survey.{Tools, Task}
  alias Core.Authorization

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
      title = Faker.Lorem.sentence()

      content_node = Factories.insert!(:content_node)
      study = Factories.insert!(:study)

      promotion =
        Factories.insert!(:promotion, %{
          title: title,
          study: study,
          parent_content_node: content_node
        })

      assert {:ok, %Tool{} = _survey_tool} =
               Tools.create_survey_tool(
                 %{},
                 study,
                 promotion,
                 content_node
               )

      assert promotion.title == title
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

    test "delete_survey_tool/1 deletes the survey tool even with participations attached" do
      survey_tool = Factories.insert!(:survey_tool)
      participant = Factories.insert!(:member)
      Tools.apply_participant(survey_tool, participant)
      assert {:ok, %{}} = Tools.delete_survey_tool(survey_tool)
      assert_raise Ecto.NoResultsError, fn -> Tools.get_survey_tool!(survey_tool.id) end
    end

    test "change_survey_tool/1 returns a survey_tool changeset" do
      survey_tool = Factories.insert!(:survey_tool)
      assert %Ecto.Changeset{} = Tools.change_survey_tool(survey_tool, :mount)
    end

    test "apply_participant/2 creates application" do
      survey_tool = Factories.insert!(:survey_tool)
      member = Factories.insert!(:researcher)
      assert {:ok, _} = Tools.apply_participant(survey_tool, member)
    end

    test "apply_participant/2 notifies the researchers" do
      survey_tool = Factories.insert!(:survey_tool)
      researcher = Factories.insert!(:researcher)
      promotion = Core.Promotions.get!(survey_tool.promotion_id)

      study = Core.Studies.get_study!(survey_tool.study_id)
      Authorization.assign_role(researcher, study, :owner)
      member = Factories.insert!(:researcher)
      {:ok, _} = Tools.apply_participant(survey_tool, member)

      assert Systems.NotificationCenter.list(researcher) |> Enum.map(& &1.title) == [
               "New participant for: #{promotion.title}"
             ]
    end

    test "apply_participant/2 assigns the participant role to the applicant" do
      survey_tool = Factories.insert!(:survey_tool)
      member = Factories.insert!(:member)
      assert Authorization.list_roles(member, survey_tool) == MapSet.new()
      assert {:ok, _} = Tools.apply_participant(survey_tool, member)
      assert Authorization.list_roles(member, survey_tool) == MapSet.new([:participant])
    end

    test "list_participants/1 lists all participants" do
      survey = Factories.insert!(:survey_tool)
      _non_particpant = Factories.insert!(:researcher)
      applied_participant = Factories.insert!(:researcher)
      Tools.apply_participant(survey, applied_participant)

      assert Tools.list_participants(survey)
             |> Enum.map(&%{user_id: &1.user.id}) == [
               %{user_id: applied_participant.id}
             ]
    end

    test "list_participations/1 list all studies a user is a part of" do
      survey_tool = Factories.insert!(:survey_tool)
      member = Factories.insert!(:member)
      # Listing without any participation should return an empty list
      assert Tools.list_participations(member) == []
      # The listing should contain the survey tool after an application has been made
      Tools.apply_participant(survey_tool, member)
      assert Tools.list_participations(member) |> Enum.map(& &1.id) == [survey_tool.id]
    end

    test "get_task/2 returns a task when available" do
      survey_tool_task = Factories.insert!(:survey_tool_task)

      assert Tools.get_task(survey_tool_task.tool, survey_tool_task.user)
             |> Map.take([:user_id, :tool_id]) ==
               survey_tool_task |> Map.take([:user_id, :tool_id])
    end

    test "setup_tasks_for_participants/2 creates task for participants" do
      survey_tool = Factories.insert!(:survey_tool)

      participant = Factories.insert!(:survey_tool_participant, %{survey_tool: survey_tool})

      assert Tools.setup_tasks_for_participants!([participant], survey_tool)
             |> Enum.count() == 1

      assert Tools.list_tasks(survey_tool) |> Enum.map(& &1.user_id) == [
               participant.user_id
             ]
    end

    test "list_participants_without_task/2 returns the participants for a study that do not have a survey task" do
      survey_tool = Factories.insert!(:survey_tool)
      assert Tools.list_participants_without_task(survey_tool) == []

      participant_without_task =
        Factories.insert!(:survey_tool_participant, %{survey_tool: survey_tool})

      assert Tools.list_participants_without_task(survey_tool)
             |> Enum.map(& &1.user_id) ==
               [participant_without_task.user_id]

      %Task{
        user: participant_without_task.user,
        tool: survey_tool,
        status: :pending
      }
      |> Core.Repo.insert!()

      assert Tools.list_participants_without_task(survey_tool) == []
    end

    test "list_tasks/1 returns the tasks for a survery tool" do
      task = Factories.insert!(:survey_tool_task)
      survey_tool = task.tool

      assert Tools.list_tasks(survey_tool) |> Enum.map(& &1.user_id) == [task.user_id]
    end

    test "complete_task/2 marks a survey tool task as completed" do
      task = Factories.insert!(:survey_tool_task)
      survey_tool = task.tool

      assert Tools.complete_task!(task)
      assert Tools.get_task(survey_tool, task.user).status == :completed
    end

    test "participant_id/1 returns the id for the participant" do
      survey_tool = Factories.insert!(:survey_tool)
      member = Factories.insert!(:member)
      {:ok, _} = Tools.apply_participant(survey_tool, member)
      assert Tools.participant_id(survey_tool, member) == 1
      # A second participant will get the next number
      member = Factories.insert!(:member)
      {:ok, _} = Tools.apply_participant(survey_tool, member)
      assert Tools.participant_id(survey_tool, member) == 2
      # The numbering system is unique per survey
      survey_tool = Factories.insert!(:survey_tool)
      {:ok, _} = Tools.apply_participant(survey_tool, member)
      assert Tools.participant_id(survey_tool, member) == 1
    end
  end
end
