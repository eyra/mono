defmodule CoreWeb.Features.WorkflowItemGroupFieldTest do
  @moduledoc """
  Verifies that the workflow item form's "group" (platform/source) field can be
  hidden per template via `Workflow.Config.group_enabled?`.

  - Questionnaire template (used by Panl): group field hidden
  - Data donation template: group field visible
  """
  use CoreWeb.FeatureCase

  @card_selector "[data-testid^='card_']"
  @group_field_selector "[data-testid$='_item_form_group']"

  @tag :feature
  feature "questionnaire template hides the group field on workflow items", %{session: session} do
    researcher = create_and_login_researcher(session)

    create_project(researcher)
    create_project_item(researcher, "questionnaire")
    open_assignment_cms(researcher)
    open_workflow_tab(researcher)
    add_library_item(researcher, "manual")
    expand_cell(researcher)

    # Group field should NOT be visible for the questionnaire template
    refute_has(researcher, Query.css(@group_field_selector))
  end

  @tag :feature
  feature "data donation template shows the group field on workflow items", %{session: session} do
    researcher = create_and_login_researcher(session)

    create_project(researcher)
    create_project_item(researcher, "data_donation")
    open_assignment_cms(researcher)
    open_workflow_tab(researcher)
    add_library_item(researcher, "manual")
    expand_cell(researcher)

    # Group field SHOULD be visible for data donation template
    researcher
    |> assert_has(Query.css(@group_field_selector))
  end

  defp create_and_login_researcher(session) do
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
  end

  defp create_project(session) do
    session
    |> assert_has(Query.css("[data-testid='create-first-project-button']"))
    |> click(Query.css("[data-testid='create-first-project-button']"))
    |> assert_has(Query.css(@card_selector, count: 1))
    |> click(Query.css(@card_selector))
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
  end

  defp create_project_item(session, template) do
    session
    |> assert_has(Query.css("[data-testid='create-first-item-button']"))
    |> click(Query.css("[data-testid='create-first-item-button']"))
    |> assert_has(Query.css("[data-testid='selector-item-#{template}']"))
    |> click(Query.css("[data-testid='selector-item-#{template}']"))
    |> click(Query.css("[data-testid='create-item-button']"))
  end

  defp open_assignment_cms(session) do
    session
    |> assert_has(Query.css(@card_selector, count: 1))
    |> click(Query.css(@card_selector))
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
  end

  defp open_workflow_tab(session) do
    session
    |> assert_has(Query.css("[data-testid='assignment-tab-workflow']"))
    |> click(Query.css("[data-testid='assignment-tab-workflow']"))
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
  end

  defp add_library_item(session, item_id) do
    session
    |> assert_has(Query.css("[data-testid='add-library-item-#{item_id}']"))
    |> click(Query.css("[data-testid='add-library-item-#{item_id}']"))
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
  end

  defp expand_cell(session) do
    session
    |> assert_has(Query.css(".cell-expand-button"))
    |> click(Query.css(".cell-expand-button"))
  end
end
