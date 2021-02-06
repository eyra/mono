defmodule Link.StudiesTest do
  use Link.DataCase

  alias Link.Studies

  describe "studies" do
    alias Link.Studies.Study
    alias Link.{Factories, Authorization}

    @valid_attrs %{description: "some description", title: "some title"}
    @update_attrs %{description: "some updated description", title: "some updated title"}
    @invalid_attrs %{description: nil, title: nil}

    test "list_studies/1 returns all studies" do
      study = Factories.insert!(:study)
      assert Studies.list_studies() |> Enum.map(& &1.id) == [study.id]
    end

    test "list_studies/1 allows excluding a list of ids" do
      studies = 0..3 |> Enum.map(fn _ -> Factories.insert!(:study) end)
      {excluded_study, expected_result} = List.pop_at(studies, 1)

      assert Studies.list_studies(exclude: [excluded_study.id]) |> Enum.map(& &1.id) ==
               expected_result |> Enum.map(& &1.id)
    end

    test "list_owned_studies/1 returns only studies that are owned by the user" do
      _not_owned = Factories.insert!(:study)
      researcher = Factories.insert!(:researcher)
      owned = Factories.insert!(:study)
      :ok = Authorization.assign_role(researcher, owned, :owner)
      assert Studies.list_owned_studies(researcher) |> Enum.map(& &1.id) == [owned.id]
    end

    test "get_study!/1 returns the study with given id" do
      study = Factories.insert!(:study)
      assert Studies.get_study!(study.id).title == study.title
    end

    test "create_study/1 with valid data creates a study" do
      assert {:ok, %Study{} = study} =
               Studies.create_study(@valid_attrs, Factories.insert!(:researcher))

      assert study.description == "some description"
      assert study.title == "some title"
    end

    test "create_study/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Studies.create_study(@invalid_attrs, Factories.insert!(:researcher))
    end

    test "update_study/2 with valid data updates the study" do
      study = Factories.insert!(:study)
      assert {:ok, %Study{} = study} = Studies.update_study(study, @update_attrs)
      assert study.description == "some updated description"
      assert study.title == "some updated title"
    end

    test "update_study/2 with invalid data returns error changeset" do
      study = Factories.insert!(:study)
      assert {:error, %Ecto.Changeset{}} = Studies.update_study(study, @invalid_attrs)
    end

    test "delete_study/1 deletes the study" do
      study = Factories.insert!(:study)
      assert {:ok, %Study{}} = Studies.delete_study(study)
      assert_raise Ecto.NoResultsError, fn -> Studies.get_study!(study.id) end
    end

    test "delete_study/1 deletes the study even with participations attached" do
      study = Factories.insert!(:study)
      participant = Factories.insert!(:member)
      Studies.apply_participant(study, participant)
      assert {:ok, %Study{}} = Studies.delete_study(study)
      assert_raise Ecto.NoResultsError, fn -> Studies.get_study!(study.id) end
    end

    test "change_study/1 returns a study changeset" do
      study = Factories.insert!(:study)
      assert %Ecto.Changeset{} = Studies.change_study(study)
    end

    test "apply_participant/2 creates application" do
      study = Factories.insert!(:study)
      member = Factories.insert!(:researcher)
      assert {:ok, _} = Studies.apply_participant(study, member)
    end

    test "application_status/2 informs if a member has applied to a study" do
      study = Factories.insert!(:study)
      member = Factories.insert!(:researcher)
      assert Studies.application_status(study, member) |> is_nil
      Studies.apply_participant(study, member)
      assert Studies.application_status(study, member) == :applied
    end

    test "update_participant_status/3 alters the status of a participant" do
      study = Factories.insert!(:study)
      member = Factories.insert!(:researcher)
      Studies.apply_participant(study, member)
      assert :ok = Studies.update_participant_status(study, member, :entered)
      assert Studies.application_status(study, member) == :entered
    end

    test "update_participant_status/3 alters permission for a participant" do
      study = Factories.insert!(:study)
      member = Factories.insert!(:researcher)
      Studies.apply_participant(study, member)

      assert Authorization.list_roles(member, study) == MapSet.new()

      assert :ok = Studies.update_participant_status(study, member, :entered)

      assert Authorization.list_roles(member, study) == MapSet.new([:participant])

      assert :ok = Studies.update_participant_status(study, member, :rejected)

      # Rejecting a participant makes them lose their priviliges
      assert Authorization.list_roles(member, study) == MapSet.new()
    end

    test "list_participants/1 lists all participants" do
      study = Factories.insert!(:study)
      _non_particpant = Factories.insert!(:researcher)
      applied_participant = Factories.insert!(:researcher)
      Studies.apply_participant(study, applied_participant)
      accepted_participant = Factories.insert!(:researcher)
      Studies.apply_participant(study, accepted_participant)
      Studies.update_participant_status(study, accepted_participant, :entered)
      rejected_participant = Factories.insert!(:researcher)
      Studies.apply_participant(study, rejected_participant)
      Studies.update_participant_status(study, rejected_participant, :rejected)
      # Both members that applied should be listed with their corresponding status.
      assert Studies.list_participants(study)
             |> Enum.map(&%{status: &1.status, user_id: &1.user.id}) == [
               %{status: :applied, user_id: applied_participant.id},
               %{status: :entered, user_id: accepted_participant.id},
               %{status: :rejected, user_id: rejected_participant.id}
             ]
    end

    test "list_participations/1 list all studies a user is a part of" do
      study = Factories.insert!(:study)
      member = Factories.insert!(:member)
      # Listing without any participation should return an empty list
      assert Studies.list_participations(member) == []
      # The listing should contain the study after an application has been made
      Studies.apply_participant(study, member)
      assert Studies.list_participations(member) |> Enum.map(& &1.id) == [study.id]
    end

    test "add_owner!/2 grants a user ownership over a study" do
      researcher_1 = Factories.insert!(:researcher)
      researcher_2 = Factories.insert!(:researcher)
      study = Factories.insert!(:study)
      :ok = Authorization.assign_role(researcher_1, study, :owner)
      # The second researcher is not the owner of the study
      assert Studies.list_owned_studies(researcher_2) == []
      Studies.add_owner!(study, researcher_2)
      # The second researcher is now an owner of the study
      assert Studies.list_owned_studies(researcher_2) |> Enum.map(& &1.id) == [study.id]
    end

    test "assign_owners/2 adds or removes a users ownership of a study" do
      researcher_1 = Factories.insert!(:researcher)
      researcher_2 = Factories.insert!(:researcher)
      study = Factories.insert!(:study)
      :ok = Authorization.assign_role(researcher_1, study, :owner)
      # The second researcher is not the owner of the study
      assert Studies.list_owned_studies(researcher_2) == []
      Studies.assign_owners(study, [researcher_2])
      # The second researcher is now an owner of the study
      assert Studies.list_owned_studies(researcher_2) |> Enum.map(& &1.id) == [study.id]
      # The original owner can no longer claim ownership
      assert Studies.list_owned_studies(researcher_1) == []
    end

    test "list_owners/1 returns all users with ownership permission on the study" do
      researcher_1 = Factories.insert!(:researcher)
      researcher_2 = Factories.insert!(:researcher)
      study = Factories.insert!(:study)
      :ok = Authorization.assign_role(researcher_1, study, :owner)
      assert Studies.list_owners(study) |> Enum.map(& &1.id) == [researcher_1.id]
      Studies.assign_owners(study, [researcher_2])
      assert Studies.list_owners(study) |> Enum.map(& &1.id) == [researcher_2.id]
    end
  end
end
