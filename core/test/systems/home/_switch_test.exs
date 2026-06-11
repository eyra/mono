defmodule Systems.Home.SwitchTest do
  use Core.DataCase, async: false

  alias Frameworks.Signal
  alias Systems.Home
  alias Systems.Observatory

  describe "intercept/2 — {:fund_rewards_summary, _}" do
    test "dispatches an Observatory broadcast to Home.Page subscribers for the user" do
      user_id = 42
      model = Observatory.SingletonModel.instance()

      Observatory.Public.subscribe(Home.Page, [model.id, user_id])

      assert :ok =
               Signal.Public.dispatch(
                 {:fund_rewards_summary, :updated},
                 %{user_id: user_id}
               )

      assert_received %Phoenix.Socket.Broadcast{
        event: "observation",
        payload: {Systems.Home.Page, %{model: %{id: :singleton}}}
      }
    end

    test "does not broadcast on the wrong user's topic" do
      acting_user_id = 100
      other_user_id = 200
      model = Observatory.SingletonModel.instance()

      Observatory.Public.subscribe(Home.Page, [model.id, other_user_id])

      assert :ok =
               Signal.Public.dispatch(
                 {:fund_rewards_summary, :updated},
                 %{user_id: acting_user_id}
               )

      refute_received %Phoenix.Socket.Broadcast{event: "observation"}
    end
  end
end
