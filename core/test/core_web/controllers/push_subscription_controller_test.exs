defmodule CoreWeb.PushSubscriptionControllerTest do
  use CoreWeb.ConnCase

  alias Core.WebPush.PushSubscription

  @valid_attrs %{
    endpoint: "some endpoint",
    expirationTime: 42,
    keys: %{
      auth: "some auth",
      p256dh: "some p256dh"
    }
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "register" do
    setup [:login_as_member]

    test "register a subscription", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.push_subscription_path(conn, :register), subscription: @valid_attrs)

      assert json_response(conn, 200) == %{}
      assert Core.Repo.get_by(PushSubscription, user_id: user.id) != nil
    end
  end

  describe "vapid_public_key" do
    setup [:login_as_member]

    test "return the public key", %{conn: conn} do
      conn = get(conn, Routes.push_subscription_path(conn, :vapid_public_key))

      assert is_binary(response(conn, 200))
    end
  end
end
