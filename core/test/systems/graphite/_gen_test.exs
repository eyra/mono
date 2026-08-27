defmodule Systems.Graphite.GenTest do
  use Core.DataCase

  import Ecto.Query
  import Systems.Graphite.Gen

  alias Core.Authorization.RoleAssignment
  alias Core.Repo
  alias Systems.Account.FeaturesModel
  alias Systems.Account.User
  alias Systems.Account.UserProfileModel
  alias Systems.Graphite
  alias Systems.Graphite.Factories
  alias Systems.Graphite.SubmissionModel

  describe "create_submissions/3" do
    test "create 2 submissions" do
      %{id: leaderboard_id} = Factories.create_leaderboard(%{})
      create_submissions(leaderboard_id, 2, "aap")

      assert [
               %SubmissionModel{
                 description: "aap-1",
                 auth_node: %Core.Authorization.Node{
                   parent_id: nil,
                   role_assignments: [
                     %RoleAssignment{
                       principal_id: principal_1_id,
                       role: :owner
                     }
                   ]
                 }
               },
               %SubmissionModel{
                 description: "aap-2",
                 auth_node: %Core.Authorization.Node{
                   parent_id: nil,
                   role_assignments: [
                     %RoleAssignment{
                       principal_id: principal_2_id,
                       role: :owner
                     }
                   ]
                 }
               }
             ] =
               from(SubmissionModel)
               |> Repo.all()
               |> Repo.preload(auth_node: [:role_assignments])
               |> Enum.sort_by(& &1.description)

      assert [
               %User{
                 id: ^principal_1_id,
                 displayname: "aap-1"
               },
               %User{
                 id: ^principal_2_id,
                 displayname: "aap-2"
               }
             ] =
               from(User)
               |> Repo.all()
               |> Enum.sort_by(& &1.id)

      assert [%FeaturesModel{}, %FeaturesModel{}] = Repo.all(from(FeaturesModel))

      assert [%UserProfileModel{}, %UserProfileModel{}] = Repo.all(from(UserProfileModel))
    end
  end

  describe "delete_submissions/1" do
    test "create and delete 2 submissions" do
      %{id: leaderboard_id} = Factories.create_leaderboard(%{})
      create_submissions(leaderboard_id, 2, "aap")
      delete_submissions("aap")

      assert [] = Repo.all(from(Graphite.ScoreModel))
      assert [] = Repo.all(from(SubmissionModel))
      assert [] = Repo.all(from(User))
      assert [] = Repo.all(from(FeaturesModel))
      assert [] = Repo.all(from(UserProfileModel))
    end
  end
end
