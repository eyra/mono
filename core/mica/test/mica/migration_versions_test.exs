defmodule Mica.MigrationVersionsTest do
  # Two migrations with the same version break `mix ecto.migrate` for everyone, and
  # whichever PR merges second only finds out on develop. Branches pick versions
  # independently, so this checks it before the merge.
  use ExUnit.Case, async: true

  test "no two migrations share a version" do
    versions =
      for path <- Mica.SaaS.migrations_paths(),
          file <- Path.wildcard(Path.join(path, "*.exs")),
          [version | _] = file |> Path.basename() |> String.split("_"),
          do: {version, Path.basename(file)}

    duplicates =
      versions
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> Enum.filter(fn {_version, files} -> length(files) > 1 end)

    assert duplicates == []
  end
end
