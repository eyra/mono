defmodule MicaSaas.Systems.Admin.LicensesModalViewTest do
  use MicaSaasWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test

  import Phoenix.LiveViewTest

  alias Systems.Admin
  alias Systems.License
  alias Systems.Org

  setup %{conn: conn} do
    set_feature_flag(:panl_post_launch, true)
    researcher = Factories.insert!(:creator, %{email: "researcher@uni.test"})
    %{conn: Map.put(conn, :request_path, "/admin/accounts"), researcher: researcher}
  end

  defp open(conn, researcher) do
    {:ok, view, _html} =
      live_isolated(conn, Admin.LicensesModalView, session: %{"user_id" => researcher.id})

    view
  end

  defp as_admin(%{conn: conn}) do
    {:ok, conn: conn, user: admin} = login_as_admin(%{conn: conn})
    {conn, admin}
  end

  defp pick(view, license, period) do
    render_click(view, "toggle_periods", %{"license" => license})
    render_click(view, "pick_period", %{"license" => license, "period" => period})
  end

  describe "for a system admin" do
    setup ctx do
      {conn, admin} = as_admin(ctx)
      %{conn: conn, admin: admin}
    end

    test "shows Publish and Pay-in with their state", %{conn: conn, researcher: researcher} do
      view = open(conn, researcher)

      assert has_element?(view, "[data-testid='license-publish-status']", "Off")
      assert has_element?(view, "[data-testid='license-pay_in-status']", "Off")
    end

    test "shows only Publish without :panl_post_launch", %{conn: conn, researcher: researcher} do
      set_feature_flag(:panl_post_launch, false)
      view = open(conn, researcher)

      assert has_element?(view, "[data-testid='license-publish']")
      refute has_element?(view, "[data-testid='license-pay_in']")
    end

    test "names the research institute under Pay-in, and only there",
         %{conn: conn, admin: admin, researcher: researcher} do
      org = Org.Public.create_node!(["uni_test"], [{:en, "UNI"}], [{:en, "Test University"}])
      {:ok, org} = Org.Public.mark_research_institute(org, true, admin)
      :ok = Org.Public.add_member(org, researcher, admin)

      view = open(conn, researcher)

      assert has_element?(view, "[data-testid='license-pay_in-institutes']", "Test University")
      refute has_element?(view, "[data-testid='license-publish-institutes']")
    end

    test "warns under Pay-in, and only there, when the researcher has no research institute",
         %{conn: conn, researcher: researcher} do
      view = open(conn, researcher)

      assert has_element?(view, "[data-testid='license-pay_in-institute-warning']")
      refute has_element?(view, "[data-testid='license-publish-institute-warning']")
    end

    test "gives Pay-in for 1 year", %{conn: conn, admin: admin, researcher: researcher} do
      view = open(conn, researcher)

      render_click(view, "toggle", %{"license" => "pay_in"})
      pick(view, "pay_in", "year_1")
      render_click(view, "save", %{})

      assert %{valid_until: valid_until, granted_by_id: granted_by_id} =
               License.Public.get_current(researcher, :pay_in)

      assert valid_until == License.Public.end_date(:year_1)
      assert granted_by_id == admin.id
      refute License.Public.active?(researcher, :publish)
    end

    test "gives both licenses to a researcher outside any research institute",
         %{conn: conn, researcher: researcher} do
      view = open(conn, researcher)

      for license <- ["publish", "pay_in"] do
        render_click(view, "toggle", %{"license" => license})
        pick(view, license, "days_90")
      end

      render_click(view, "save", %{})

      assert License.Public.active?(researcher, :publish)
      assert License.Public.active?(researcher, :pay_in)
    end

    test "gives Publish until a custom date", %{conn: conn, researcher: researcher} do
      end_date = Date.add(Date.utc_today(), 45)
      view = open(conn, researcher)

      render_click(view, "toggle", %{"license" => "publish"})
      pick(view, "publish", "custom")

      view
      |> element("[data-testid='license-publish-custom-form']")
      |> render_change(%{"license" => "publish", "custom_date" => Date.to_iso8601(end_date)})

      render_click(view, "save", %{})

      assert %{valid_until: ^end_date} = License.Public.get_current(researcher, :publish)
    end

    test "refuses a custom date in the past and says what to fix",
         %{conn: conn, researcher: researcher} do
      view = open(conn, researcher)

      render_click(view, "toggle", %{"license" => "publish"})
      pick(view, "publish", "custom")

      view
      |> element("[data-testid='license-publish-custom-form']")
      |> render_change(%{"license" => "publish", "custom_date" => "2020-01-01"})

      html = render_click(view, "save", %{})

      assert html =~ "Choose a date after today."
      assert License.Public.get_current(researcher, :publish) == nil
    end

    test "says to choose an end date when a license is switched on without one",
         %{conn: conn, researcher: researcher} do
      view = open(conn, researcher)

      render_click(view, "toggle", %{"license" => "publish"})
      html = render_click(view, "save", %{})

      assert html =~ "Choose when the license ends."
      assert License.Public.get_current(researcher, :publish) == nil
    end

    test "the save button is never disabled", %{conn: conn, researcher: researcher} do
      view = open(conn, researcher)
      render_click(view, "toggle", %{"license" => "publish"})

      refute has_element?(view, "[data-testid='licenses-save'][disabled]")
    end

    test "switches Publish off", %{conn: conn, admin: admin, researcher: researcher} do
      Factories.insert!(:license, %{user: researcher})
      view = open(conn, researcher)

      render_click(view, "toggle", %{"license" => "publish"})
      render_click(view, "save", %{})

      assert %{revoked_by_id: revoked_by_id} = License.Public.get_current(researcher, :publish)
      assert revoked_by_id == admin.id
      refute License.Public.active?(researcher, :publish)
    end
  end

  describe "for someone who isn't a system admin" do
    test "a crafted save changes nothing", %{conn: conn, researcher: researcher} do
      {:ok, conn: conn, user: _} = login(Factories.insert!(:creator), %{conn: conn})
      view = open(conn, researcher)

      render_click(view, "toggle", %{"license" => "pay_in"})
      pick(view, "pay_in", "year_1")
      html = render_click(view, "save", %{})

      assert html =~ "Only system admins can change licenses."
      assert License.Public.get_current(researcher, :pay_in) == nil
    end

    test "the researcher can't give themselves a license", %{conn: conn, researcher: researcher} do
      {:ok, conn: conn, user: _} = login(researcher, %{conn: conn})
      view = open(conn, researcher)

      render_click(view, "toggle", %{"license" => "publish"})
      pick(view, "publish", "year_1")
      render_click(view, "save", %{})

      refute License.Public.active?(researcher, :publish)
    end
  end
end
