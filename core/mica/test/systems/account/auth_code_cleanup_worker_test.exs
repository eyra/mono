defmodule Systems.Account.AuthCodeCleanupWorkerTest do
  use Mica.DataCase, async: true
  use Oban.Testing, repo: Mica.Repo

  import Ecto.Query

  alias Mica.Repo
  alias Systems.Account
  alias Systems.Account.AuthCodeCleanupWorker
  alias Systems.Account.AuthCodeModel
  alias Systems.Rate

  @validity_in_minutes 10

  defp insert_auth_code(email, minutes_ago) do
    {_code, auth_code} = AuthCodeModel.build(email, nil)
    inserted = Repo.insert!(auth_code)

    ts =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-minutes_ago * 60, :second)
      |> NaiveDateTime.truncate(:second)

    from(t in AuthCodeModel, where: t.id == ^inserted.id)
    |> Repo.update_all(set: [inserted_at: ts])

    Repo.get!(AuthCodeModel, inserted.id)
  end

  defp auth_code_count do
    Repo.aggregate(AuthCodeModel, :count)
  end

  describe "perform/1" do
    test "deletes auth codes older than the validity window" do
      insert_auth_code("expired@example.com", @validity_in_minutes + 1)

      assert :ok = perform_job(AuthCodeCleanupWorker, %{})
      assert auth_code_count() == 0
    end

    test "keeps auth codes inside the validity window" do
      insert_auth_code("fresh@example.com", 1)

      assert :ok = perform_job(AuthCodeCleanupWorker, %{})
      assert auth_code_count() == 1
    end

    test "deletes only expired rows when both exist" do
      fresh = insert_auth_code("fresh@example.com", 1)
      insert_auth_code("expired@example.com", @validity_in_minutes + 1)

      assert :ok = perform_job(AuthCodeCleanupWorker, %{})

      remaining = Repo.all(AuthCodeModel)
      assert length(remaining) == 1
      assert hd(remaining).id == fresh.id
    end

    test "returns :ok when there is nothing to delete" do
      assert :ok = perform_job(AuthCodeCleanupWorker, %{})
    end

    test "deletes rate counters whose window has ended" do
      Rate.Public.increment_counter("ended", 3600)

      Repo.update_all(Rate.CounterModel,
        set: [window_start: ~U[2000-01-01 00:00:00Z], expires_at: ~U[2000-01-01 01:00:00Z]]
      )

      Rate.Public.increment_counter("current", 3600)

      assert :ok = perform_job(AuthCodeCleanupWorker, %{})
      assert 1 = Rate.Public.counter("current", 3600)
      assert 1 = Repo.aggregate(Rate.CounterModel, :count)
    end
  end

  describe "Account.Public.cleanup_expired_auth_codes/0" do
    test "returns the number of rows deleted" do
      insert_auth_code("expired-1@example.com", @validity_in_minutes + 1)
      insert_auth_code("expired-2@example.com", @validity_in_minutes + 5)
      insert_auth_code("fresh@example.com", 1)

      assert Account.Public.cleanup_expired_auth_codes() == 2
    end

    test "returns 0 when nothing is expired" do
      insert_auth_code("fresh@example.com", 1)

      assert Account.Public.cleanup_expired_auth_codes() == 0
    end
  end
end
