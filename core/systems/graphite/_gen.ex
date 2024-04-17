defmodule Systems.Graphite.Gen do
  alias Core.Factories
  alias Systems.Graphite

  @doc """
  Create `amount` submissions for the specified `leaderboard`, where the
  submission description is created with the `prefix`, followed by a
  number.
  """
  def create_submissions(leaderboard_id, amount, prefix) do
    Application.ensure_all_started(:core)

    leaderboard = Graphite.Public.get_leaderboard!(leaderboard_id, [{:tool, :auth_node}])

    multi = Ecto.Multi.new()

    {:ok, result} =
      Enum.reduce(1..amount, multi, fn i, multi ->
        name = "#{prefix}-#{i}"

        multi
        |> create_user(name)
        |> create_auth_node(name)
        |> create_submission(name, leaderboard.tool)
      end)
      |> Core.Repo.transaction(returning: true)

    submission_count = count(result, :submission)
    user_count = count(result, :user)

    print("#{submission_count} submissions created")
    print("#{user_count} users created")
  end

  defp print(message) do
    IO.puts(IO.ANSI.green() <> message <> IO.ANSI.reset())
  end

  defp count(result, type) do
    result
    |> Map.keys()
    |> Enum.count(fn {key, _} -> key == type end)
  end

  defp gen_commit_url() do
    s = for _ <- 1..40, into: "", do: <<Enum.random('0123456789abcdefghijklmnopqrstuvwxyz')>>

    "https://github.com/eyra/mono/commit/" <> s
  end

  defp create_submission(multi, name, tool) do
    Ecto.Multi.insert(multi, {:submission, name}, fn %{{:auth_node, ^name} => auth_node} ->
      Core.Factories.build(:graphite_submission, %{
        tool: tool,
        auth_node: auth_node,
        github_commit_url: gen_commit_url(),
        description: name
      })
    end)
  end

  defp create_user(multi, name) do
    password = Factories.valid_user_password()
    member = Factories.build(:member, %{displayname: name, password: password})
    Ecto.Multi.insert(multi, {:user, name}, member)
  end

  defp create_auth_node(multi, name) do
    Ecto.Multi.insert(multi, {:auth_node, name}, fn %{{:user, ^name} => user} ->
      Core.Authorization.prepare_node(user, :owner)
    end)
  end

  @doc """
  Delete the submissions where the submission description starts
  with `prefix`.
  """
  def delete_submissions(prefix) do
    Application.ensure_all_started(:core)

    submissions_to_delete = Graphite.Queries.submissions_by_prefix(:description, prefix)
    users_to_delete = Core.Accounts.Queries.users_by_prefix(:displayname, prefix)
    features_to_delete = Core.Accounts.Queries.features_by_users(users_to_delete)
    profiles_to_delete = Core.Accounts.Queries.profiles_by_users(users_to_delete)

    {:ok, result} =
      Ecto.Multi.new()
      |> Ecto.Multi.delete_all(:submissions, submissions_to_delete)
      |> Ecto.Multi.delete_all(:features, features_to_delete)
      |> Ecto.Multi.delete_all(:profiles, profiles_to_delete)
      |> Ecto.Multi.delete_all(:users, users_to_delete)
      |> Core.Repo.transaction()

    %{
      submissions: {submission_count, nil},
      users: {user_count, nil}
    } = result

    print("#{submission_count} submissions deleted")
    print("#{user_count} users deleted")
  end
end
