defmodule Frameworks.Utility.QueryTest do
  use Core.DataCase

  require Ecto.Query
  require Frameworks.Utility.Query

  alias Frameworks.Utility.Query
  alias Systems.Crew
  alias Core.Factories

  describe "compile_clauses/1" do
    test "join: 1" do
      assert [[:join, :member, :crew]] = Query.compile_clauses([:crew], :member)
    end

    test "join: 2, depth: 1" do
      assert [
               [:join, :member, :crew],
               [:join, :member, :user]
             ] = Query.compile_clauses([:crew, :user], :member)
    end

    test "join: 2, depth: 2" do
      assert [
               [:join, :member, :crew],
               [:join, :crew, :auth_node]
             ] = Query.compile_clauses([crew: [:auth_node]], :member)
    end

    test "join: 3, filter: 1, depth: 2" do
      assert [
               [:join, :member, :crew],
               [:join, :crew, :auth_node],
               [:join, :auth_node, :role_assignments],
               [:where, :role_assignments, {:==, [], [:role, :owner]}]
             ] =
               Query.compile_clauses(
                 [crew: [auth_node: [role_assignments: [{:==, [], [:role, :owner]}]]]],
                 :member
               )
    end
  end

  describe "build/3" do
    test "join: 3, filter: 1, depth: 2" do
      user = %{id: user_id} = Factories.insert!(:member)
      crew = %{id: crew_id} = Factories.insert!(:crew)
      Crew.Public.apply_member(crew, user, ["task1"])

      role = :participant

      query =
        Ecto.Query.from(m in Crew.MemberModel, as: :member)
        |> Query.build(:member,
          crew: [
            id == ^crew_id,
            auth_node: [
              role_assignments: [
                role == ^role
              ]
            ]
          ],
          user: [id == ^user_id]
        )

      assert %{
               aliases: %{member: 0, crew: 1, auth_node: 2, role_assignments: 3},
               from: %Ecto.Query.FromExpr{
                 source: {"crew_members", Systems.Crew.MemberModel},
                 as: :member
               },
               joins: [
                 %Ecto.Query.JoinExpr{
                   qual: :inner,
                   assoc: {0, :crew},
                   as: :crew
                 },
                 %Ecto.Query.JoinExpr{
                   qual: :inner,
                   source: nil,
                   assoc: {1, :auth_node},
                   as: :auth_node
                 },
                 %Ecto.Query.JoinExpr{
                   qual: :inner,
                   source: nil,
                   assoc: {2, :role_assignments},
                   as: :role_assignments
                 },
                 %Ecto.Query.JoinExpr{
                   qual: :inner,
                   assoc: {0, :user},
                   as: :user
                 }
               ],
               wheres: [
                 %Ecto.Query.BooleanExpr{
                   op: :and,
                   expr: {:==, [], [{{:., [], [{:&, [], [1]}, :id]}, [], []}, {:^, [], [0]}]},
                   params: [{^crew_id, {1, :id}}],
                   subqueries: []
                 },
                 %Ecto.Query.BooleanExpr{
                   op: :and,
                   expr: {:==, [], [{{:., [], [{:&, [], [3]}, :role]}, [], []}, {:^, [], [0]}]},
                   params: [participant: {3, :role}]
                 },
                 %Ecto.Query.BooleanExpr{
                   op: :and,
                   expr: {:==, [], [{{:., [], [{:&, [], [4]}, :id]}, [], []}, {:^, [], [0]}]},
                   params: [{^user_id, {4, :id}}]
                 }
               ]
             } = query |> Map.from_struct()

      assert %Systems.Crew.MemberModel{
               user_id: ^user_id
             } = Core.Repo.one(query)
    end

    test "is_nil with result" do
      %{id: user_id} = Factories.insert!(:member)

      query =
        Ecto.Query.from(u in Core.Accounts.User, as: :user)
        |> Query.build(:user, profile: [title == nil])

      assert %{
               wheres: [
                 %Ecto.Query.BooleanExpr{
                   expr: {:is_nil, [], [{{:., [], [{:&, [], [1]}, :title]}, [], []}]}
                 }
               ]
             } = query |> Map.from_struct()

      assert %Core.Accounts.User{
               id: ^user_id
             } = Core.Repo.one(query)
    end
  end

  test "is_nil without result" do
    Factories.insert!(:member)

    query =
      Ecto.Query.from(u in Core.Accounts.User, as: :user)
      |> Query.build(:user, [id == nil])

    assert %{
             wheres: [
               %Ecto.Query.BooleanExpr{
                 expr: {:is_nil, [], [{{:., [], [{:&, [], [0]}, :id]}, [], []}]}
               }
             ]
           } = query |> Map.from_struct()

    assert nil == Core.Repo.one(query)
  end
end
