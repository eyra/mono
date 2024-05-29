defmodule Systems.Promotion.LandingPageTest do
  use CoreWeb.ConnCase
  # import Phoenix.ConnTest
  # import Phoenix.LiveViewTest

  alias Systems.Assignment
  # alias Systems.Promotion
  # alias Systems.Crew
  alias Systems.Budget

  describe "show landing page for: advert -> assignment -> alliance_tool" do
    setup [:login_as_member]

    setup do
      advert_auth_node = Factories.insert!(:auth_node)
      promotion_auth_node = Factories.insert!(:auth_node, %{parent: advert_auth_node})
      assignment_auth_node = Factories.insert!(:auth_node, %{parent: advert_auth_node})
      tool_auth_node = Factories.insert!(:auth_node, %{parent: assignment_auth_node})

      currency = Budget.Factories.create_currency("test_1234", :legal, "ƒ", 2)
      budget = Budget.Factories.create_budget("test_1234", currency)

      pool =
        Factories.insert!(:pool, %{name: "test_1234", director: :citizen, currency: currency})

      tool = Assignment.Factories.create_tool(tool_auth_node)
      tool_ref = Assignment.Factories.create_tool_ref(tool)
      workflow = Assignment.Factories.create_workflow()
      _workflow_item = Assignment.Factories.create_workflow_item(workflow, tool_ref)
      info = Assignment.Factories.create_info("10", 10)

      assignment =
        Assignment.Factories.create_assignment(
          info,
          workflow,
          assignment_auth_node,
          budget
        )

      promotion =
        Factories.insert!(
          :promotion,
          %{
            director: :advert,
            title: "This is a test title",
            themes: ["marketing", "econometrics"],
            expectations: "These are the expectations for the participants",
            description: "Something about this study",
            banner_title: "Banner Title",
            banner_subtitle: "Banner Subtitle",
            banner_photo_url: "https://eyra.co/image/1",
            banner_url: "https://eyra.co/member/1",
            marks: ["vu"],
            auth_node: promotion_auth_node
          }
        )

      submission = Factories.insert!(:pool_submission, %{reward_value: 500, pool: pool})

      _advert =
        Factories.insert!(:advert, %{
          assignment: assignment,
          promotion: promotion,
          submission: submission,
          auth_node: advert_auth_node
        })

      %{promotion: promotion, assignment: assignment, submission: submission}
    end

    # test "Initial", %{conn: conn, promotion: promotion} do
    #   assert_raise RuntimeError, fn ->
    #     {:ok, _view, html} =
    #       live(conn, ~p"/promotion/#{promotion.id}")

    #     assert html =~ "This is a test title"
    #     assert html =~ "These are the expectations for the participants"
    #     assert html =~ "Marketing, Econometrie"
    #     assert html =~ "Wat kun je verwachten?"
    #     assert html =~ "These are the expectations for the participants"
    #     assert html =~ "Over deze studie"
    #     assert html =~ "Something about this study"
    #     assert html =~ "This is a test title"
    #     assert html =~ "Ik doe mee"
    #     assert html =~ "Duur"
    #     assert html =~ "10 minuten"
    #     assert html =~ "Beloning"
    #     assert html =~ "ƒ5,00"
    #     assert html =~ "Status"
    #     assert html =~ "Open voor deelname"
    #     assert html =~ "Beschikbaar op:"
    #     assert html =~ "desktop.svg"
    #   end
    # end

    # test "One member applied", %{conn: conn, promotion: promotion, assignment: assignment} do
    #   user = Factories.insert!(:member)
    #   {:ok, %{member: _member}} = Crew.Public.apply_member(assignment.crew, user, ["task1"])

    #   assert_raise RuntimeError, fn ->
    #     {:ok, _view, html} =
    #       live(conn, ~p"/promotion/#{promotion.id}")

    #     assert html =~ "Open voor deelname"
    #   end
    # end

    # test "Apply current user", %{conn: conn, promotion: promotion} do
    #   assert_raise RuntimeError, fn ->
    #     {:ok, view, _html} =
    #       live(conn, ~p"/promotion/#{promotion.id}")

    #     html =
    #       view
    #       |> element("[phx-click=\"call-to-action-1\"]")
    #       |> render_click()

    #     # FIXME
    #     assert {:error, {:live_redirect, %{kind: :push, to: to}}} = html
    #     assert to =~ "/assignment/"
    #   end
    # end
  end
end
