defmodule Core.Release do
  @moduledoc false
  @app :core

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Seeds a test creator account for Playwright tests.
  Only use on dev/test environments, never on production.
  """
  def seed_test_user do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(Core.Repo, fn _repo ->
        alias Systems.Account

        email = "test-creator@eyra.co"
        password = "TestCreator123!"

        case Core.Repo.get_by(Account.User, email: email) do
          nil ->
            now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
            hashed_password = Bcrypt.hash_pwd_salt(password)

            {:ok, user} =
              %Account.User{}
              |> Ecto.Changeset.change(%{
                email: email,
                hashed_password: hashed_password,
                creator: true,
                confirmed_at: now,
                verified_at: now
              })
              |> Core.Repo.insert()

            IO.puts("Created test user: #{user.email}")

          existing ->
            IO.puts("Test user already exists: #{existing.email}")
        end
      end)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    :ssl.start()
    Application.load(@app)
  end
end
