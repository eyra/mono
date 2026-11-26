defmodule Mica.Release do
  alias Systems.Account
  alias Systems.License

  @app Mica.Env.app()

  @doc "Runs the migrations of Mica and the SaaS's systems (`Mica.SaaS.migrations_paths/0`)."
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(
          repo,
          &Ecto.Migrator.run(&1, Mica.SaaS.migrations_paths(), :up, all: true)
        )
    end
  end

  @doc """
  Runs idempotent seeds for the current deploy environment.
  Should be invoked from the release startup script after `migrate/0`.
  """
  def seed do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, fn _repo -> Mica.Seeds.seed() end)
    end
  end

  def rollback(repo, version) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(
        repo,
        &Ecto.Migrator.run(&1, Mica.SaaS.migrations_paths(), :down, to: version)
      )
  end

  @doc """
  Seeds a test creator account for Playwright tests, with a Publish license.
  An existing test creator whose Publish license has ended gets a new one.
  Only use on dev/test environments, never on production.
  """
  def seed_test_user do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(Mica.Repo, fn _repo ->
        ensure_test_user(Mica.Repo.get_by(Account.User, email: test_user_email()))
      end)
  end

  @doc "The email address of the test creator `seed_test_user/0` seeds."
  def test_user_email, do: "test-creator@eyra.co"

  defp ensure_test_user(nil) do
    {:ok, %{user: user}} =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:user, test_user_changeset(test_user_email()))
      |> Ecto.Multi.run(:license, fn _repo, %{user: user} -> give_publish(user) end)
      |> Mica.Repo.commit()

    IO.puts("Created test user: #{user.email}")
  end

  defp ensure_test_user(existing) do
    ensure_publish(existing)
    IO.puts("Test user already exists: #{existing.email}")
  end

  defp test_user_changeset(email) do
    Ecto.Changeset.change(%Account.User{}, %{
      email: email,
      hashed_password: Bcrypt.hash_pwd_salt("TestCreator123!"),
      creator: true,
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })
  end

  defp ensure_publish(user) do
    unless License.Public.active?(user, :publish), do: {:ok, _} = give_publish(user)
  end

  defp give_publish(user),
    do: License.Public.grant(user, :publish, License.Public.end_date(:year_1))

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  # A release task starts no apps; license end dates need the time zone data.
  defp load_app do
    :ssl.start()
    Application.load(@app)
    {:ok, _} = Application.ensure_all_started(:tzdata)
  end
end
