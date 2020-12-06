defmodule Link.SurveyToolsTest do
  use Link.DataCase

  alias Link.SurveyTools

  describe "survey_tools" do
    alias Link.Studies
    alias Link.SurveyTools.SurveyTool
    alias Link.Users

    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}
    @researcher %{
      email: Faker.Internet.email(),
      password: "S4p3rS3cr3t",
      password_confirmation: "S4p3rS3cr3t"
    }
    @study %{description: "some description", title: "some title"}

    def researcher_fixture(attrs \\ %{}) do
      {:ok, user} = attrs |> Enum.into(@researcher) |> Users.create()
      user
    end

    def study_fixture(attrs \\ %{}) do
      researcher = researcher_fixture()

      {:ok, study} =
        attrs
        |> Enum.into(@study)
        |> Studies.create_study(researcher)

      study
    end

    def survey_tool_fixture(attrs \\ %{}) do
      study = study_fixture()

      {:ok, survey_tool} =
        attrs
        |> Enum.into(@valid_attrs)
        |> SurveyTools.create_survey_tool(study)

      survey_tool
    end

    test "list_survey_tools/0 returns all survey_tools" do
      survey_tool = survey_tool_fixture()
      assert SurveyTools.list_survey_tools() |> Enum.map(fn s -> s.id end) == [survey_tool.id]
    end

    test "get_survey_tool!/1 returns the survey_tool with given id" do
      survey_tool = survey_tool_fixture()
      assert SurveyTools.get_survey_tool!(survey_tool.id).id == survey_tool.id
    end

    test "create_survey_tool/1 with valid data creates a survey_tool" do
      assert {:ok, %SurveyTool{} = survey_tool} =
               SurveyTools.create_survey_tool(@valid_attrs, study_fixture())

      assert survey_tool.title == "some title"
    end

    test "create_survey_tool/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               SurveyTools.create_survey_tool(@invalid_attrs, study_fixture())
    end

    test "update_survey_tool/2 with valid data updates the survey_tool" do
      survey_tool = survey_tool_fixture()

      assert {:ok, %SurveyTool{} = survey_tool} =
               SurveyTools.update_survey_tool(survey_tool, @update_attrs)

      assert survey_tool.title == "some updated title"
    end

    test "update_survey_tool/2 with invalid data returns error changeset" do
      survey_tool = survey_tool_fixture()

      assert {:error, %Ecto.Changeset{}} =
               SurveyTools.update_survey_tool(survey_tool, @invalid_attrs)

      assert survey_tool.id == SurveyTools.get_survey_tool!(survey_tool.id).id
    end

    test "delete_survey_tool/1 deletes the survey_tool" do
      survey_tool = survey_tool_fixture()
      assert {:ok, %SurveyTool{}} = SurveyTools.delete_survey_tool(survey_tool)
      assert_raise Ecto.NoResultsError, fn -> SurveyTools.get_survey_tool!(survey_tool.id) end
    end

    test "change_survey_tool/1 returns a survey_tool changeset" do
      survey_tool = survey_tool_fixture()
      assert %Ecto.Changeset{} = SurveyTools.change_survey_tool(survey_tool)
    end
  end
end
