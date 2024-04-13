defmodule Systems.Graphite.Gen do
  import Ecto.Query

  alias Core.Factories
  alias Systems.Graphite

  @doc """
  Create `amount` submissions for the specified `leaderboard`, where the
  submission description is created with the `prefix`, followed by a
  number.
  """
  def create_submissions(leaderboard_id, amount, prefix) do
    leaderboard = Graphite.Public.get_leaderboard!(leaderboard_id, [{:tool, :auth_node}])

    multi = Ecto.Multi.new()

    Enum.reduce(1..amount, multi, fn i, multi ->
      name = "#{prefix}-#{i}"

      multi
      |> create_user(name)
      |> create_auth_node(name)
      |> create_submission(name, leaderboard.tool)
    end)
    |> Core.Repo.transaction(returning: true)
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
    submissions_to_delete = get_submissions(prefix)
    # users_to_delete = get_users(prefix)

    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(:submissions, submissions_to_delete)
    # |> Ecto.Multi.delete_all(:users, users_to_delete)
    |> Core.Repo.transaction()
  end

  defp get_submissions(prefix) do
    like = "#{prefix}-%"

    from(submission in Graphite.SubmissionModel,
      where: like(submission.description, ^like)
    )
  end

  def get_users(prefix) do
    like = "#{prefix}-%"

    from(user in Core.Accounts.User,
      where: like(user.displayname, ^like)
    )
  end
end
