defmodule MicaSaasWeb.Features.LicensesTest do
  @moduledoc """
  UC-LINK-02: support finds a researcher on Admin → Users, opens Licenses,
  switches Pay-in on for 1 year and Publish on for 90 days, and saves. The
  dialog warns under Pay-in that the researcher has no research institute.
  """
  use MicaSaasWeb.FeatureCase
  use Mica.FeatureFlags.Test

  alias Systems.License

  @tag :feature
  feature "support gives a researcher Pay-in and Publish", %{session: session} do
    set_feature_flag(:panl_post_launch, true)

    password = Factories.valid_user_password()
    support = Factories.insert!(:member, %{email: "admin1@example.org", password: password})

    researcher =
      Factories.insert!(:creator, %{
        email: "researcher@uni.test",
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

    licenses_button = "[phx-click='licenses'][phx-value-item='#{researcher.id}']"

    session
    |> sign_in(support, password)
    |> visit("/admin/config?tab=account")
    |> assert_connected(licenses_button)
    |> click(Query.css(licenses_button))
    |> assert_has(Query.css("[data-testid='licenses-modal']"))
    |> assert_has(Query.css("[data-testid='license-pay_in-institute-warning']"))
    |> click(Query.css("[data-testid='license-pay_in-checkbox']"))
    |> click(Query.css("[data-testid='license-pay_in-select']"))
    |> click(Query.css("[data-testid='license-pay_in-period-year_1']"))
    |> click(Query.css("[data-testid='license-publish-checkbox']"))
    |> click(Query.css("[data-testid='license-publish-select']"))
    |> click(Query.css("[data-testid='license-publish-period-days_90']"))
    |> click(Query.css("[data-testid='licenses-save']"))
    |> retry_until(fn -> License.Public.active?(researcher, :pay_in) end)
    |> click(Query.css(licenses_button))
    |> assert_has(Query.css("[data-testid='license-pay_in-status']", text: "On until"))
    |> assert_has(Query.css("[data-testid='license-publish-status']", text: "On until"))

    assert %{valid_until: pay_in_until, granted_by_id: granted_by_id} =
             License.Public.get_current(researcher, :pay_in)

    assert pay_in_until == License.Public.end_date(:year_1)
    assert granted_by_id == support.id

    assert %{valid_until: publish_until} = License.Public.get_current(researcher, :publish)
    assert publish_until == License.Public.end_date(:days_90)
  end

  defp retry_until(session, check, attempts \\ 50) do
    cond do
      check.() -> session
      attempts == 0 -> flunk("condition not met")
      true -> Process.sleep(100) && retry_until(session, check, attempts - 1)
    end
  end
end
