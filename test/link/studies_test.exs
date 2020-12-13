defmodule Link.StudiesTest do
  use Link.DataCase

  alias Link.Studies

  describe "studies" do
    alias Link.Studies.Study
    alias Link.Users

    @researcher %{
      email: Faker.Internet.email(),
      password: "S4p3rS3cr3t",
      password_confirmation: "S4p3rS3cr3t"
    }
    @valid_attrs %{description: "some description", title: "some title"}
    @update_attrs %{description: "some updated description", title: "some updated title"}
    @invalid_attrs %{description: nil, title: nil}

    def researcher_fixture(attrs \\ %{}) do
      {:ok, user} = attrs |> Enum.into(@researcher) |> Users.create()
      user
    end

    def study_fixture(attrs \\ %{}) do
      researcher = researcher_fixture()

      {:ok, study} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Studies.create_study(researcher)

      study
    end

    test "list_studies/0 returns all studies" do
      study = study_fixture()
      assert Studies.list_studies() == [study]
    end

    test "get_study!/1 returns the study with given id" do
      study = study_fixture()
      assert Studies.get_study!(study.id).title == study.title
    end

    test "create_study/1 with valid data creates a study" do
      assert {:ok, %Study{} = study} = Studies.create_study(@valid_attrs, researcher_fixture())
      assert study.description == "some description"
      assert study.title == "some title"
    end

    test "create_study/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Studies.create_study(@invalid_attrs, researcher_fixture())
    end

    test "update_study/2 with valid data updates the study" do
      study = study_fixture()
      assert {:ok, %Study{} = study} = Studies.update_study(study, @update_attrs)
      assert study.description == "some updated description"
      assert study.title == "some updated title"
    end

    test "update_study/2 with invalid data returns error changeset" do
      study = study_fixture()
      assert {:error, %Ecto.Changeset{}} = Studies.update_study(study, @invalid_attrs)
    end

    test "delete_study/1 deletes the study" do
      study = study_fixture()
      assert {:ok, %Study{}} = Studies.delete_study(study)
      assert_raise Ecto.NoResultsError, fn -> Studies.get_study!(study.id) end
    end

    test "change_study/1 returns a study changeset" do
      study = study_fixture()
      assert %Ecto.Changeset{} = Studies.change_study(study)
    end

    test "apply_participant/2 creates application" do
      study = study_fixture()
      member = researcher_fixture(email: Faker.Internet.email())
      assert {:ok, _} = Studies.apply_participant(study, member)
    end

    test "application_status/2 informs if a member has applied to a study" do
      study = study_fixture()
      member = researcher_fixture(email: Faker.Internet.email())
      assert Studies.application_status(study, member) |> is_nil
      Studies.apply_participant(study, member)
      assert Studies.application_status(study, member) == :applied
    end

    test "enter_particpant/2 accepts a participant into the study" do
      study = study_fixture()
      member = researcher_fixture(email: Faker.Internet.email())
      Studies.apply_participant(study, member)
      assert :ok = Studies.enter_participant(study, member)
      assert Studies.application_status(study, member) == :entered
    end

    test "list_participants/1 lists all participants" do
      study = study_fixture()
      _non_particpant = researcher_fixture(email: Faker.Internet.email())
      applied_participant = researcher_fixture(email: Faker.Internet.email())
      Studies.apply_participant(study, applied_participant)
      accepted_participant = researcher_fixture(email: Faker.Internet.email())
      Studies.apply_participant(study, accepted_participant)
      Studies.enter_participant(study, accepted_participant)
      # Both members that applied should be listed with their corresponding status.
      assert Studies.list_participants(study) == [
               %{status: :applied, user_id: applied_participant.id},
               %{status: :entered, user_id: accepted_participant.id}
             ]
    end
  end
end
