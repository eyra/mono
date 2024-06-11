defmodule CoreWeb.APNSDeviceTokenControllerTest do
  use CoreWeb.ConnCase

  setup [:login_as_member]

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create device token" do
    test "returns ok when creating a new token", %{conn: conn} do
      conn = post(conn, ~p"/api/apns-token", device_token: "some-token")
      assert response(conn, 200)
    end
  end
end
