defmodule Mica.GiveCreatorsATransitionPublishLicenseTest do
  # Every creator who could publish before licenses keeps Publish for 90 days. The
  # users are written with the migration rolled back, `verified_at` set in SQL as
  # the schema no longer has it, then migrated, inside the test's transaction.
  use Mica.DataCase, async: false

  alias Mica.Repo
  alias Systems.License

  @migration Mica.Repo.Migrations.GiveCreatorsATransitionPublishLicense
  @migration_file Path.wildcard(
                    "priv/repo/migrations/*_give_creators_a_transition_publish_license.exs"
                  )
                  |> List.first()
  @version @migration_file |> Path.basename() |> String.split("_") |> hd() |> String.to_integer()

  setup_all do
    unless Code.ensure_loaded?(@migration), do: Code.compile_file(@migration_file)
    :ok
  end

  setup do
    :ok = Ecto.Migrator.down(Repo, @version, @migration, log: false, migration_lock: false)
    :ok
  end

  defp migrate,
    do: :ok = Ecto.Migrator.up(Repo, @version, @migration, log: false, migration_lock: false)

  defp user!(attrs, verified?) do
    user = Factories.insert!(:member, attrs)

    if verified? do
      Repo.query!("UPDATE users SET verified_at = now() WHERE id = $1", [user.id])
    end

    user
  end

  test "a creator who could publish gets Publish until 90 days from now" do
    creator = user!(%{creator: true}, true)

    migrate()

    assert %License.Model{granted_by_id: nil, revoked_at: nil, valid_until: valid_until} =
             License.Public.get_current(creator, :publish)

    assert valid_until == Date.add(Date.utc_today(), 90)
  end

  test "the creator can publish after the migration" do
    creator = user!(%{creator: true}, true)

    migrate()

    assert License.Public.active?(creator, :publish)
  end

  test "a creator support had unverified doesn't get Publish" do
    unverified = user!(%{creator: true}, false)

    migrate()

    refute License.Public.active?(unverified, :publish)
  end

  test "a member who isn't a creator doesn't get Publish" do
    member = user!(%{creator: false}, true)

    migrate()

    refute License.Public.active?(member, :publish)
  end

  test "nobody gets Pay-in" do
    creator = user!(%{creator: true}, true)

    migrate()

    refute License.Public.active?(creator, :pay_in)
  end

  test "marks users.verified_at as deprecated" do
    migrate()

    %{rows: [[comment]]} =
      Repo.query!("SELECT col_description('users'::regclass, attnum) FROM pg_attribute
                   WHERE attrelid = 'users'::regclass AND attname = 'verified_at'")

    assert comment =~ "DEPRECATED"
  end
end
