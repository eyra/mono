defmodule Systems.Graphite.GenTest do
  use Core.DataCase

  import Ecto.Query
  import Systems.Graphite.Gen

  alias Core.Repo
  alias Systems.Graphite
  alias Systems.Graphite.Factories

  describe "create_submissions/3" do
    test "create 2 submissions" do
      %{id: leaderboard_id} = Factories.create_leaderboard(%{})
      create_submissions(leaderboard_id, 2, "aap")

      assert [
               %Systems.Graphite.SubmissionModel{
                 description: "aap-1",
                 auth_node: %Core.Authorization.Node{
                   parent_id: nil,
                   role_assignments: [
                     %Core.Authorization.RoleAssignment{
                       principal_id: principal_1_id,
                       role: :owner
                     }
                   ]
                 }
               },
               %Systems.Graphite.SubmissionModel{
                 description: "aap-2",
                 auth_node: %Core.Authorization.Node{
                   parent_id: nil,
                   role_assignments: [
                     %Core.Authorization.RoleAssignment{
                       principal_id: principal_2_id,
                       role: :owner
                     }
                   ]
                 }
               }
             ] =
               from(Graphite.SubmissionModel)
               |> Repo.all()
               |> Repo.preload(auth_node: [:role_assignments])
               |> Enum.sort_by(& &1.description)

      assert [
               %Systems.Account.User{
                 id: ^principal_1_id,
                 displayname: "aap-1"
               },
               %Systems.Account.User{
                 id: ^principal_2_id,
                 displayname: "aap-2"
               }
             ] =
               from(Systems.Account.User)
               |> Repo.all()
               |> Enum.sort_by(& &1.id)

      assert [
               %Systems.Account.FeaturesModel{},
               %Systems.Account.FeaturesModel{}
             ] = from(Systems.Account.FeaturesModel) |> Repo.all()

      assert [
               %Systems.Account.UserProfileModel{},
               %Systems.Account.UserProfileModel{}
             ] = from(Systems.Account.UserProfileModel) |> Repo.all()
    end
  end

  describe "delete_submissions/1" do
    test "create and delete 2 submissions" do
      %{id: leaderboard_id} = Factories.create_leaderboard(%{})
      create_submissions(leaderboard_id, 2, "aap")
      delete_submissions("aap")

      assert [] = from(Graphite.ScoreModel) |> Repo.all()
      assert [] = from(Graphite.SubmissionModel) |> Repo.all()
      assert [] = from(Systems.Account.User) |> Repo.all()
      assert [] = from(Systems.Account.FeaturesModel) |> Repo.all()
      assert [] = from(Systems.Account.UserProfileModel) |> Repo.all()
    end
  end
end
