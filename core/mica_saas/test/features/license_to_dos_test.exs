defmodule MicaSaasWeb.Features.LicenseToDosTest do
  @moduledoc """
  UC-LINK-02 part 2: support gives a researcher Publish for 30 days in the
  Licenses dialog, and the researcher's open To-do page shows it. 14 days
  before the end date the daily run (with a fixed clock) replaces it with the
  reminder, which opens the helpdesk page. The To-dos' copy is tested in
  `MicaSaas.Systems.License.ToDoTest`.
  """
  use MicaSaasWeb.FeatureCase
  use Mica.FeatureFlags.Test

  alias Systems.License
  alias Systems.NextAction

  @given_to_do "#next-actions a[href='/project']"
  @reminder_to_do "#next-actions a[href='/support/helpdesk']"

  @sessions 2
  @tag :feature
  feature "the researcher is told about the license and reminded before it ends",
          %{sessions: [support_session, researcher_session]} do
    set_feature_flag(:panl_post_launch, true)

    password = Factories.valid_user_password()
    support = Factories.insert!(:member, %{email: "admin1@example.org", password: password})

    researcher = create_confirmed_user("researcher@uni.test", password, creator: true)

    licenses_button = "[phx-click='licenses'][phx-value-item='#{researcher.id}']"

    researcher_session
    |> sign_in(researcher, password)
    |> visit("/todo")
    |> assert_connected("#zero-todos")

    support_session
    |> sign_in(support, password)
    |> visit("/admin/config?tab=account")
    |> assert_connected(licenses_button)
    |> click(Query.css(licenses_button))
    |> click(Query.css("[data-testid='license-publish-checkbox']"))
    |> click(Query.css("[data-testid='license-publish-select']"))
    |> click(Query.css("[data-testid='license-publish-period-days_30']"))
    |> click(Query.css("[data-testid='licenses-save']"))

    researcher_session
    |> assert_has(Query.css(@given_to_do))

    assert [%{action_type: License.NextActions.Given}] =
             NextAction.Public.list_next_actions(researcher)

    # The daily run, 14 days before the end date
    end_date = License.Public.end_date(:days_30)
    reminder_day = end_date |> Date.add(-14) |> DateTime.new!(~T[12:00:00], "Etc/UTC")
    assert License.Public.remind(reminder_day) == 1

    researcher_session
    |> assert_has(Query.css(@reminder_to_do))
    |> assert_has(Query.css("#next-actions:not(:has(a[href='/project']))"))
    |> click(Query.css(@reminder_to_do))
    |> assert_path_changed_from("/todo")

    assert current_path(researcher_session) == "/support/helpdesk"
  end
end
