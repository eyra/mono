defmodule Next.Config.RuntimeSnapshotTest do
  # Replaces the process environment while each fixture is evaluated.
  use ExUnit.Case, async: false

  alias Mix.Tasks.Config.Snapshot

  for fixture <- Snapshot.fixtures() do
    @fixture fixture
    test "runtime config for #{fixture.name} matches its snapshot" do
      assert Snapshot.render(@fixture) == File.read!(@fixture.snapshot), """
      The runtime config for #{@fixture.name} changed. Review the change, then run
      `mix config.snapshot --update` and commit the snapshot diff.
      """
    end
  end
end
