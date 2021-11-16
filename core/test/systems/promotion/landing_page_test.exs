defmodule Systems.Promotion.LandingPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Systems.{
    Promotion,
    Crew
  }

  describe "show landing page for: campaign -> assignment -> survey_tool" do
    setup [:login_as_member]

    setup do
      survey_tool =
        Factories.insert!(
          :survey_tool,
          %{
            survey_url: "https://eyra.co/fake_survey",
            subject_count: 10,
            duration: "10",
            language: "en",
            devices: [:desktop]
          }
        )

      assignment =
        Factories.insert!(
          :assignment,
          %{
            survey_tool: survey_tool
          }
        )

      promotion =
        Factories.insert!(
          :promotion,
          %{
            director: :campaign,
            title: "This is a test title",
            themes: ["marketing", "econometrics"],
            expectations: "These are the expectations for the participants",
            description: "Something about this study",
            banner_title: "Banner Title",
            banner_subtitle: "Banner Subtitle",
            banner_photo_url: "https://eyra.co/image/1",
            banner_url: "https://eyra.co/member/1",
            marks: ["vu"]
          }
        )

      _submission = Factories.insert!(:submission, %{reward_value: 5, promotion: promotion})
      author = Factories.build(:author)

      _campaign =
        Factories.insert!(:campaign, %{
          assignment: assignment,
          promotion: promotion,
          authors: [author]
        })

      %{promotion: promotion, assignment: assignment}
    end

    test "Initial", %{conn: conn, promotion: promotion} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Promotion.LandingPage, promotion.id))
      assert html =~ "This is a test title"
      assert html =~ "These are the expectations for the participants"
      assert html =~ "Marketing, Econometrics"
      assert html =~ "What to expect?"
      assert html =~ "These are the expectations for the participants"
      assert html =~ "About this study"
      assert html =~ "Something about this study"
      assert html =~ "This is a test title"
      assert html =~ "Participate"
      assert html =~ "Duration"
      assert html =~ "10 minutes"
      assert html =~ "Reward"
      assert html =~ "5 credits"
      assert html =~ "Status"
      assert html =~ "Open for participation"
      assert html =~ "Available on:"
      assert html =~ "desktop.svg"
    end

    test "One member applied", %{conn: conn, promotion: promotion, assignment: assignment} do
      user = Factories.insert!(:member)
      _member = Crew.Context.apply_member!(assignment.crew, user)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Promotion.LandingPage, promotion.id))
      assert html =~ "Open for participation"
    end

    test "Apply current user", %{conn: conn, promotion: promotion} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Promotion.LandingPage, promotion.id))

      html =
        view
        |> element("[phx-click=\"call-to-action-1\"]")
        |> render_click()

      # FIXME
      assert {:error, {:live_redirect, %{kind: :push, to: to}}} = html
      assert to =~ "/assignment/"
    end
  end
end
