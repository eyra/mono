defmodule Mica.DeleteEmailChangeTokensTest do
  # /user/settings no longer changes an email address; the migration deletes the
  # tokens its confirmation links used. Tokens are written with the migration
  # rolled back, then migrated, inside the test's transaction.
  use Mica.DataCase, async: false

  alias Mica.Repo
  alias Systems.Account.UserTokenModel

  @migration Mica.Repo.Migrations.DeleteEmailChangeTokens
  @migration_file Path.wildcard("priv/repo/migrations/*_delete_email_change_tokens.exs")
                  |> List.first()
  @version @migration_file |> Path.basename() |> String.split("_") |> hd() |> String.to_integer()

  setup_all do
    unless Code.ensure_loaded?(@migration), do: Code.compile_file(@migration_file)
    :ok
  end

  setup do
    :ok = Ecto.Migrator.down(Repo, @version, @migration, log: false, migration_lock: false)
    %{user: Factories.insert!(:member)}
  end

  defp migrate,
    do: :ok = Ecto.Migrator.up(Repo, @version, @migration, log: false, migration_lock: false)

  defp insert_token!(user, context) do
    {_encoded, token} = UserTokenModel.build_email_token(user, context)
    Repo.insert!(token)
  end

  test "deletes email-change tokens and keeps the others", %{user: user} do
    insert_token!(%{user | email: "new@example.org"}, "change:#{user.email}")
    insert_token!(user, "reset_password")
    insert_token!(user, "confirm")

    migrate()

    contexts = Repo.all(UserTokenModel) |> Enum.map(& &1.context) |> Enum.sort()
    assert contexts == ["confirm", "reset_password"]
  end
end
