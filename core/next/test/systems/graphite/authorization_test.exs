defmodule Next.Systems.Graphite.AuthorizationTest do
  use Mica.DataCase

  import ExUnit.CaptureLog

  alias Mica.Authorization
  alias Mica.Factories

  setup do
    level = Logger.level()
    Logger.configure(level: :notice)
    on_exit(fn -> Logger.configure(level: level) end)
  end

  test "print_roles/1 names a Graphite leaderboard, a schema the SaaS adds" do
    %{auth_node_id: node_id} = leaderboard = Factories.insert!(:graphite_leaderboard)

    assert capture_log(fn -> Authorization.print_roles(leaderboard) end) =~
             "0 roles for Graphite.LeaderboardModel ##{node_id}"
  end
end
