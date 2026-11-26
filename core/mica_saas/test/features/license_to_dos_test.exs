defmodule MicaSaasWeb.Features.LicenseToDosTest do
  @moduledoc """
  UC-LINK-02 part 2: support gives a researcher Publish for 30 days in the
  Licenses dialog, and the researcher's open To-do page shows it. 14 days
  before the end date the daily run (with a fixed clock) replaces it with the
  reminder; clicking it marks the notification seen and opens the helpdesk
  page. The To-dos' copy is tested in `MicaSaas.Systems.License.ToDoTest`.
  """
  use MicaSaasWeb.FeatureCase
  use Mica.FeatureFlags.Test

  alias Mica.Repo
  alias Systems.License
  alias Systems.NextAction
  alias Systems.Notify

  # The button of the researcher's To-do of `type`: it opens its notification.
  defp to_do_button(%{id: user_id}, type) do
    %{params: %{"notify_message_id" => message_id}} =
      Repo.get_by!(NextAction.Model, user_id: user_id, action: to_string(type))

    "a[href='/notify/open/#{message_id}']"
  end

  # Waits for the save to enqueue its tell, then runs it.
  defp run_tell_job(attempts \\ 50) do
    case Oban.drain_queue(queue: :default) do
      %{success: 0} when attempts > 0 ->
        Process.sleep(100)
        run_tell_job(attempts - 1)

      %{success: 0} ->
        flunk("the save enqueued no tell")

      _drained ->
        :ok
    end
  end

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

    # The save's tell is a job (`License.TellWorker`); run it as Oban would.
    run_tell_job()

    researcher_session
    |> assert_has(Query.css("#next-actions a[href^='/notify/open/']"))

    given = to_do_button(researcher, License.NextActions.Given)
    assert_has(researcher_session, Query.css("#next-actions #{given}"))

    # The daily run, 14 days before the end date
    end_date = License.Public.end_date(:days_30)
    reminder_day = end_date |> Date.add(-14) |> DateTime.new!(~T[12:00:00], "Etc/UTC")
    assert License.Public.remind(reminder_day) == 1

    reminder = to_do_button(researcher, License.NextActions.Reminder)

    researcher_session
    |> assert_has(Query.css("#next-actions #{reminder}"))
    |> assert_has(Query.css("#next-actions:not(:has(#{given}))"))
    |> click(Query.css("#next-actions #{reminder}"))
    |> assert_connected("#helpdesk_content")

    assert current_path(researcher_session) == "/support/helpdesk"
    assert NextAction.Public.list_next_actions(researcher) == []

    assert [%{status: :seen}, %{status: :seen}] =
             Repo.all(Notify.MessageModel) |> Enum.sort_by(& &1.id)
  end
end
