defmodule LinkWeb.MemberFrontpageControllerTest do
  use LinkWeb.ConnCase

  alias Link.Factories

  setup %{conn: conn} do
    member = Factories.get_or_create_user()
    conn = Pow.Plug.assign_current_user(conn, member, otp_app: :link_web)

    {:ok, conn: conn, member: member}
  end

  describe "index" do
    test "list all available studies", %{conn: conn} do
      titles = ["Analytical Engine", "FLOW-MATIC"]
      titles |> Enum.map(&Factories.create_study(title: &1))
      conn = get(conn, Routes.member_frontpage_path(conn, :index))

      for title <- titles do
        assert html_response(conn, 200) =~ title
      end
    end
  end
end
