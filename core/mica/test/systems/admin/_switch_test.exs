defmodule Systems.Admin.SwitchTest do
  @moduledoc """
  Regression coverage for FX#9905887344 — Admin.OrgView shows the same
  AddDomainMembers NextAction banner as Desktop and must rebuild its
  view model when NextActions change so the banner disappears live.
  """
  use Mica.DataCase, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Frameworks.Signal
  alias Mica.Repo
  alias Systems.Account
  alias Systems.Admin
  alias Systems.Observatory

  describe "intercept/2" do
    setup do
      topic = "signal:#{Systems.Admin.OrgView}:singleton"
      Mica.SaaS.endpoint().subscribe(topic)
      {:ok, topic: topic}
    end

    test "{:next_action, :created} broadcasts an Admin.OrgView observation",
         %{topic: topic} do
      :ok = Admin.Switch.intercept({:next_action, :created}, %{from_pid: self()})

      assert_receive %Phoenix.Socket.Broadcast{topic: ^topic, event: "observation"}
    end

    test "{:next_action, :cleared} broadcasts an Admin.OrgView observation",
         %{topic: topic} do
      :ok = Admin.Switch.intercept({:next_action, :cleared}, %{from_pid: self()})

      assert_receive %Phoenix.Socket.Broadcast{topic: ^topic, event: "observation"}
    end
  end

  # FX#10491517688: an admin's change to a user reaches Admin.AccountView.
  describe "an admin's change to a user" do
    test "broadcasts an Admin.AccountView observation" do
      topic = "signal:#{Systems.Admin.AccountView}:singleton"
      Mica.SaaS.endpoint().subscribe(topic)
      user = Factories.insert!(:member, %{creator: true, verified_at: nil})

      {:ok, _} =
        Systems.Account.Public.admin_update_user(user, %{verified_at: NaiveDateTime.utc_now()})

      assert_receive %Phoenix.Socket.Broadcast{topic: ^topic, event: "observation"}
    end
  end

  # FX#10491517688, review F1 of mono#2049: another admin's open Accounts view rebuilds
  # from the database when the observation arrives, so it must arrive after the commit.
  # The change commits for real here: the shared sandbox connection would show the
  # other view the uncommitted row. HoldCommit keeps the transaction open until the
  # other view has read, so an observation sent before the commit always shows.
  describe "an admin's change to a user, committed" do
    setup do
      Signal.TestHelper.override_signal_handlers([
        Admin.Switch,
        Observatory.Switch,
        __MODULE__.HoldCommit
      ])

      user =
        Sandbox.unboxed_run(Repo, fn ->
          Factories.insert!(:member, %{creator: true, verified_at: nil, confirmed_at: now()})
        end)

      on_exit(fn -> Sandbox.unboxed_run(Repo, fn -> delete_user(user) end) end)

      %{user: user}
    end

    test "another open Accounts view rebuilds with the new user", %{user: user} do
      test_pid = self()
      topic = "signal:#{Admin.AccountView}:singleton"

      spawn(fn ->
        Sandbox.unboxed_run(Repo, fn ->
          Mica.SaaS.endpoint().subscribe(topic)
          send(test_pid, :subscribed)

          receive do
            %Phoenix.Socket.Broadcast{topic: ^topic} ->
              send(test_pid, {:labels, button_labels(user)})
              send(test_pid, :read)
          after
            5_000 -> send(test_pid, {:labels, :no_observation})
          end
        end)
      end)

      assert_receive :subscribed

      Sandbox.unboxed_run(Repo, fn ->
        {:ok, _} = Account.Public.admin_update_user(user, %{verified_at: now()})
      end)

      assert_receive {:labels, ["Deactivate", "Unverify"]}, 6_000
    end
  end

  defp button_labels(%{email: email}) do
    %{users: users} =
      Admin.AccountViewBuilder.view_model(Observatory.SingletonModel.instance(), %{})

    %{action_buttons: buttons} = Enum.find(users, &(&1.email == email))
    Enum.map(buttons, & &1.face.label)
  end

  defp now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  # The factory's member has features, which don't go with the user.
  defp delete_user(%{id: id} = user) do
    Repo.delete_all(from(f in "user_features", where: f.user_id == ^id))
    Repo.delete!(user)
  end

  defmodule HoldCommit do
    use Frameworks.Signal.Handler

    # Runs after Admin.Switch, inside the change's transaction.
    @impl true
    def intercept({:user, :update_and_dispatch}, _message) do
      receive do
        :read -> :ok
      after
        500 -> :ok
      end
    end
  end
end
