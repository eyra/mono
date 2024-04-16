defmodule Systems.Graphite.GenTest do
  use Core.DataCase

  import Ecto.Query
  import Systems.Graphite.Gen

  alias Core.Repo
  alias Systems.Graphite
  alias Systems.Graphite.Factories

  describe "create_submissions/3" do
    test "create 2 submissions" do
      %{id: leaderboard_id} = Factories.create_leaderboard()
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

      assert [
               %Core.Accounts.User{
                 id: ^principal_1_id,
                 displayname: "aap-1"
               },
               %Core.Accounts.User{
                 id: ^principal_2_id,
                 displayname: "aap-2"
               }
             ] = from(Core.Accounts.User) |> Repo.all()

      assert [
               %Core.Accounts.Features{},
               %Core.Accounts.Features{}
             ] = from(Core.Accounts.Features) |> Repo.all()

      assert [
               %Core.Accounts.Profile{},
               %Core.Accounts.Profile{}
             ] = from(Core.Accounts.Profile) |> Repo.all()
    end
  end

  describe "delete_submissions/1" do
    test "create and delete 2 submissions" do
      %{id: leaderboard_id} = Factories.create_leaderboard()
      create_submissions(leaderboard_id, 2, "aap")
      delete_submissions("aap")

      assert [] = from(Graphite.SubmissionModel) |> Repo.all()
      assert [] = from(Core.Accounts.User) |> Repo.all()
      assert [] = from(Core.Accounts.Features) |> Repo.all()
      assert [] = from(Core.Accounts.Profile) |> Repo.all()
    end
  end
end
