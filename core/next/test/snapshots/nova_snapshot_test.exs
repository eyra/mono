defmodule Next.NovaSnapshotTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Nova.Snapshot

  @moduletag :tmp_dir

  # counts.exs runs `mix compile` in a subprocess, which waits for this test run's
  # build lock; CI checks it with `mix nova.snapshot`.
  test "the Next build matches its Nova snapshots" do
    if Snapshot.saas!() != :next, do: flunk("run with BUNDLE unset or BUNDLE=next")

    for {name, rendered} <- Snapshot.render(:next, counts: false) do
      path = Snapshot.path(:next, name)

      case Snapshot.compare(name, path, rendered) do
        {:differs, message} ->
          flunk("""
          #{path} differs from the Next build:
          #{message}
          If the change is intended, run `mix nova.snapshot --update` and commit the reviewed diff.
          """)

        _same_or_reordered ->
          :ok
      end
    end
  end

  describe "overlap?/2" do
    test "static paths overlap only when equal" do
      assert Snapshot.overlap?(route(:get, "/a/b"), route(:get, "/a/b"))
      refute Snapshot.overlap?(route(:get, "/a/b"), route(:get, "/a/c"))
      refute Snapshot.overlap?(route(:get, "/a"), route(:get, "/a/b"))
    end

    test "a parameter matches any segment" do
      assert Snapshot.overlap?(route(:get, "/user/:id"), route(:get, "/user/signin"))
      refute Snapshot.overlap?(route(:get, "/user/:id"), route(:get, "/user/signin/x"))
    end

    test "a glob or a forward matches everything below it" do
      assert Snapshot.overlap?(route(:get, "/images/*path"), route(:get, "/images/a/b"))
      assert Snapshot.overlap?(route(:*, "/sent_emails"), route(:get, "/sent_emails/1"))
      refute Snapshot.overlap?(route(:*, "/sent_emails"), route(:get, "/other"))
    end

    test "different verbs never overlap" do
      refute Snapshot.overlap?(route(:get, "/user/session"), route(:post, "/user/session"))
    end
  end

  describe "comparing routes" do
    test "reordering routes that cannot match the same request passes", %{tmp_dir: dir} do
      committed = write(dir, [route(:get, "/a"), route(:get, "/b")])

      assert {:reordered, _} =
               Snapshot.compare(
                 "routes.exs",
                 committed,
                 render([route(:get, "/b"), route(:get, "/a")])
               )
    end

    test "reordering routes that can match the same request fails", %{tmp_dir: dir} do
      committed = write(dir, [route(:get, "/user/signin"), route(:get, "/user/:id")])
      rendered = render([route(:get, "/user/:id"), route(:get, "/user/signin")])

      assert {:differs, message} = Snapshot.compare("routes.exs", committed, rendered)
      assert message =~ "order: get /user/signin (Plug) must stay before get /user/:id (Plug)"
    end

    test "an added route fails", %{tmp_dir: dir} do
      committed = write(dir, [route(:get, "/a")])

      assert {:differs, message} =
               Snapshot.compare(
                 "routes.exs",
                 committed,
                 render([route(:get, "/a"), route(:get, "/b")])
               )

      assert message =~ ~s(+ {:get, "/b")
    end
  end

  defp route(verb, path), do: {verb, path, Plug, [], nil, nil}

  defp render(routes), do: inspect(routes, limit: :infinity) <> "\n"

  defp write(dir, routes) do
    path = Path.join(dir, "routes.exs")
    File.write!(path, render(routes))
    path
  end
end
