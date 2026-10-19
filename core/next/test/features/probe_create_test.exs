defmodule CoreWeb.Features.ProbeCreateTest do
  @moduledoc """
  Feature test for creating a Cognitive screening (Probe) project item,
  which is behind the `:probe` feature flag.
  """
  use CoreWeb.FeatureCase
  use Core.FeatureFlags.Test

  @card_selector "[data-testid^='card_']"
  @probe_selector "[data-testid='selector-item-probe']"

  @tag :feature
  feature "researcher can create a Cognitive screening assignment when :probe is on",
          %{session: session} do
    set_feature_flag(:probe, true)

    session
    |> open_create_item_dialog()
    |> assert_has(Query.css(@probe_selector, text: "Cognitive screening"))
    |> click(Query.css(@probe_selector))
    |> click(Query.css("[data-testid='create-item-button']"))
    |> assert_has(Query.css(@card_selector, count: 1, text: "Cognitive screening"))
  end

  @tag :feature
  feature "researcher cannot pick Cognitive screening when :probe is off", %{session: session} do
    set_feature_flag(:probe, false)

    session
    |> open_create_item_dialog()
    |> assert_has(Query.css("[data-testid='selector-item-data_donation']"))
    |> refute_has(Query.css(@probe_selector))
  end

  defp open_create_item_dialog(session) do
    password = Factories.valid_user_password()

    researcher =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: true
      })

    session
    |> visit("/user/signin?tab=creator")
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: researcher.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: password)
    |> click(Query.css("[data-testid='signin-submit-button']"))
    |> assert_path_changed_from("/user/signin")
    |> assert_has(Query.css("[data-testid='create-first-project-button']"))
    |> click(Query.css("[data-testid='create-first-project-button']"))
    |> assert_has(Query.css(@card_selector, count: 1))
    |> click(Query.css(@card_selector))
    |> assert_has(Query.css("[data-testid='create-first-item-button']"))
    |> click(Query.css("[data-testid='create-first-item-button']"))
  end
end
